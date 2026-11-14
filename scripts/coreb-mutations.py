#!/usr/bin/env python3
"""Build actual CoreB-source mutants in disposable isolated worktrees.

Run from a provisioned, committed candidate, under its normal pinned opam/Lem
environment. No dependency installation, remote action, or normal source/build
mutation is performed. Each private cache is copied, never shared by symlink or
hardlink. Build/setup failures do not count as detected mutations.
"""
import argparse
from dataclasses import dataclass
import hashlib
import importlib.util
import json
import math
import os
import re
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Mutation:
    path: str
    old: str
    new: str
    fixture: str
    regenerate: bool
    verdict: str = "mismatch"
    artifact: bool = False


MUTATIONS = {
    "translation": Mutation(
        "frontend/coreb/model/translation.lem",
        "| A.ConstantInteger (A.IConstant n _ _) ->\n        Caux.mk_value_pe (C.Vloaded (C.LVspecified (C.OVinteger (Mem.integer_ival n))))",
        "| A.ConstantInteger (A.IConstant n _ _) ->\n        Caux.mk_value_pe (C.Vloaded (C.LVspecified (C.OVinteger (Mem.integer_ival (if n = 42 then 43 else n)))))",
        "tests/coreb/mutations/literal.c", True, artifact=True),
    "arithmetic": Mutation(
        "frontend/coreb/model/core_eval.lem",
        "| IOpAdd -> fun x y -> Mem.op_ival Mem_common.IntAdd x y",
        "| IOpAdd -> fun x y -> Mem.op_ival Mem_common.IntSub x y",
        "tests/coreb/mutations/arithmetic.c", True),
    "choice-order": Mutation(
        "frontend/coreb/model/driver.lem",
        'ND.pick (SK_misc ["new_drive_core_threads"]) steps >>= fun step ->',
        'ND.pick (SK_misc ["new_drive_core_threads"]) (List.reverse steps) >>= fun step ->',
        "tests/z2-probes/nd/order3.c", True),
    "observer": Mutation(
        "lean_frontend/differential/ObservationB.lean",
        "boundaryDelta before.trace after.trace",
        "boundaryDelta after.trace after.trace",
        "tests/coreb/mutations/access.c", False),
    "panic": Mutation(
        "lean_frontend/differential/EntryB.lean",
        "    finish options expected ObservationB.result toJson ObservationB.streams result",
        '    if result.visited >= 0 then return panic! "injected CoreB mutation panic"\n'
        "    finish options expected ObservationB.result toJson ObservationB.streams result",
        "tests/coreb/mutations/literal.c", False, verdict="panic"),
}


def apply_mutation(root, mutation):
    path = root / mutation.path
    text = path.read_text()
    count = text.count(mutation.old)
    if count != 1:
        raise RuntimeError(f"mutation source must match exactly once: {mutation.path} ({count} matches)")
    if mutation.old == mutation.new:
        raise RuntimeError("mutation must change the source")
    path.write_text(text.replace(mutation.old, mutation.new))


def detected(mutation, code, stdout, stderr):
    if mutation.verdict == "panic":
        return code == 2 and "INCOMPLETE:" in stderr and "injected CoreB mutation panic" in stderr
    return code == 1 and stderr.startswith("MISMATCH:")


def load_comparator(path):
    spec = importlib.util.spec_from_file_location("coreb_diff_mutation_support", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load ordinary differential comparator")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def driver_events(trace, tag=None):
    result = []
    for event in trace.events:
        observation = event.get("observation", {})
        if observation.get("channel") == "driver":
            result.extend(item for item in observation["events"] if tag is None or item.get("tag") == tag)
    return result


def verify_witness(name, a, b, structural):
    if a.outcome.get("kind") != "defined" or b.outcome.get("kind") != "defined":
        raise RuntimeError(f"{name}: source mutation did not produce two complete defined executions")
    same_outcome = structural(a.outcome) == structural(b.outcome)
    if name == "translation" and same_outcome:
        raise RuntimeError("translation: expected different literal return values")
    if name == "arithmetic":
        stores_a, stores_b = driver_events(a, "store"), driver_events(b, "store")
        if not same_outcome or not stores_a or not stores_b or structural(stores_a) == structural(stores_b):
            raise RuntimeError("arithmetic: expected changed real stores with equal terminal outcomes")
    if name == "observer":
        if not same_outcome or len(driver_events(b)) >= len(driver_events(a)):
            raise RuntimeError("observer: expected omitted driver events with equal terminal outcomes")
    if name == "choice-order":
        duplicate_choices = any(len({structural(x) for x in choice["alternatives"]}) < len(choice["alternatives"])
                                for choice in a.choices)
        if same_outcome or not duplicate_choices:
            raise RuntimeError("choice-order: expected different defined results under duplicate choice labels")


def sha256(path):
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def capture(command, cwd, timeout, env=None):
    """Own the process group and kill only it if a command times out/interrupts."""
    process = subprocess.Popen(command, cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               start_new_session=True, text=True)
    finished = False
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        finished = True
        return process.returncode, stdout, stderr
    finally:
        if not finished:
            try:
                if os.getpgid(process.pid) != process.pid:
                    raise RuntimeError("owned command changed process group")
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.communicate()


def diagnostics(label, text):
    if text.strip():
        omitted = max(0, len(text) - 6000)
        prefix = f"[{omitted} diagnostic characters omitted; rerun the named command for full output]\n" if omitted else ""
        print(f"{label}:\n{prefix}{text[-6000:]}", file=sys.stderr, flush=True)


def required(command, cwd, timeout, env=None):
    code, stdout, stderr = capture(command, cwd, timeout, env)
    if code != 0:
        raise RuntimeError(f"command failed ({code}): {' '.join(map(str, command))}\n"
                           + (stdout + stderr)[-6000:])
    label = " ".join(map(str, command))
    diagnostics(label + " stderr", stderr)
    warning_lines = "\n".join(line for line in stdout.splitlines() if re.search(r"\bwarning\b", line, re.IGNORECASE))
    diagnostics(label + " stdout warnings", warning_lines)
    return stdout


def git(root, *args):
    return required(["git", "-C", str(root), *args], root, 60).strip()


def copy_warm(source, worktree):
    # Dereference source symlinks so compiled packages and all mutable build
    # output are private. copy2/copytree do not create hardlinks.
    for relative in ["lean_frontend/.lake", "lean_frontend/generated"]:
        src, dst = source / relative, worktree / relative
        if not src.is_dir():
            raise RuntimeError(f"provisioned source directory missing: {src}")
        if dst.exists():
            raise RuntimeError(f"fresh worktree unexpectedly has {dst}")
        shutil.copytree(src, dst, symlinks=False)
    src = source / "lean_frontend/native/md5.o"
    if not src.is_file():
        raise RuntimeError(f"native object missing: {src}")
    dst = worktree / "lean_frontend/native/md5.o"
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def build_environment(worktree, memory):
    env = dict(os.environ, CERB_MEM_MAX=memory, LEAN_ABORT_ON_PANIC="1")
    # opam exec prepends its switch bin directory. Prefer the copied compiler
    # already built from the candidate's pinned LemLib when it is available;
    # otherwise inherit the ordinary provisioned opam compiler unchanged.
    package = worktree / "lean_frontend/.lake/packages/LemLib"
    compiler = package / "bin/lem"
    if compiler.is_file():
        env["PATH"] = str(compiler.parent) + os.pathsep + env.get("PATH", "")
        env["LEMLIB"] = str(package / "library")
    return env


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-checkout", type=Path, default=ROOT)
    parser.add_argument("--runtime", type=Path)
    parser.add_argument("--producer", type=Path)
    parser.add_argument("--mutant", choices=sorted(MUTATIONS), action="append")
    parser.add_argument("--build-memory", default="12G", help="CERB_MEM_MAX for isolated builds")
    parser.add_argument("--build-timeout", type=float, default=600)
    parser.add_argument("--timeout", type=float, default=30, help="per comparison child wall seconds")
    parser.add_argument("--fuel", type=int, default=1000000)
    options = parser.parse_args(argv)
    source = options.source_checkout.resolve(strict=True)
    if options.build_memory.lower() in {"none", "max", "infinity"}:
        parser.error("mutation builds require a finite memory cap")
    if (not math.isfinite(options.build_timeout) or not math.isfinite(options.timeout)
            or options.build_timeout <= 0 or options.timeout <= 0 or options.fuel <= 0):
        parser.error("timeouts and fuel must be positive")
    if git(source, "status", "--porcelain", "--untracked-files=normal"):
        raise RuntimeError("source checkout must be committed and clean before mutation trials")
    revision = git(source, "rev-parse", "HEAD")
    producer = (options.producer or source / "_build/default/backend/driver/main.exe").resolve(strict=True)
    runtime = (options.runtime or source / "_build/install/default").resolve(strict=True)
    normal_a = source / "lean_frontend/.lake/build/bin/core-diff"
    normal_b = source / "lean_frontend/.lake/build/bin/coreb-diff"
    original_hashes = (sha256(normal_a), sha256(normal_b))
    comparator = source / "scripts/coreb-diff.py"
    instrument = load_comparator(comparator)
    scratch = source / ".tmp"
    scratch.mkdir(exist_ok=True)
    results = []
    try:
        for name in options.mutant or list(MUTATIONS):
            mutation = MUTATIONS[name]
            # Witnesses are committed with this instrument; semantic source,
            # runtime and binary identities come from the chosen candidate.
            witness = ROOT / mutation.fixture
            common = [sys.executable, str(comparator), str(witness), "--producer", str(producer),
                      "--runtime", str(runtime), "--core-bin", str(normal_a),
                      "--timeout", str(options.timeout), "--fuel", str(options.fuel)]
            code, stdout, stderr = capture(common + ["--coreb-bin", str(normal_b)], source, options.timeout * 6)
            if code != 0 or not stdout.startswith("MATCH_DEFINED:"):
                raise RuntimeError(f"{name}: unmutated witness did not pass: {code}\n{stdout}\n{stderr}")
            diagnostics(f"{name} baseline stderr", stderr)
            with tempfile.TemporaryDirectory(prefix="coreb-mutant-", dir=scratch) as directory:
                worktree = Path(directory) / "checkout"
                added = False
                try:
                    git(source, "worktree", "add", "--detach", str(worktree), revision)
                    added = True
                    copy_warm(source, worktree)
                    apply_mutation(worktree, mutation)
                    git(worktree, "add", "--", mutation.path)
                    git(worktree, "commit", "-m", f"[AGENT] coreb mutation: {name} negative control")
                    env = build_environment(worktree, options.build_memory)
                    cap = str(worktree / "scripts/capped")
                    if mutation.regenerate:
                        required([cap, sys.executable, "tools/generate_coreb.py"],
                                 worktree, options.build_timeout, env)
                    targets = ["coreb-diff"] + (["coreb-pair-check"] if mutation.artifact else [])
                    required([cap, "lake", "build", *targets], worktree / "lean_frontend", options.build_timeout, env)
                    mutant_b = worktree / "lean_frontend/.lake/build/bin/coreb-diff"
                    code, stdout, stderr = capture(common + ["--coreb-bin", str(mutant_b)], source, options.timeout * 6)
                    if not detected(mutation, code, stdout, stderr):
                        raise RuntimeError(f"{name}: mutation not detected as expected: {code}\n{stdout}\n{stderr}")
                    artifact = None
                    cabs = worktree / ".tmp/mutation-input.json"
                    cabs.parent.mkdir(exist_ok=True)
                    code, text, error = instrument.run_child(
                        [str(producer), "--runtime=" + str(runtime), "--cabs-json", str(witness)],
                        options.timeout, 4096 * 1024**2, 16 * 1024**2)
                    if code != 0:
                        raise RuntimeError(f"{name}: bounded Cabs producer failed ({code}): {error[-1500:]!r}")
                    diagnostics(f"{name} Cabs producer stderr", error.decode("utf-8", errors="replace"))
                    cabs.write_bytes(text)
                    if mutation.verdict != "panic":
                        traces = []
                        for label, binary in [("A", normal_a), ("B", mutant_b)]:
                            command = [str(binary), "--runtime", str(runtime), "--input", str(cabs),
                                "--fuel", str(options.fuel), "--address-space-top", str(0xFFFFFFFFFFFF),
                                "--core-build", sha256(normal_a), "--coreb-build", sha256(mutant_b),
                                "--mode", "record", "--tape", str(worktree / f".tmp/{label}.json")]
                            code, output, error = instrument.run_child(command, options.timeout, 4096 * 1024**2, 16 * 1024**2)
                            trace = instrument.parse_trace(output)
                            if code != 0:
                                raise RuntimeError(f"{name}: witness {label} execution failed ({code}): {error[-1500:]!r}")
                            diagnostics(f"{name} {label} recorder stderr", error.decode("utf-8", errors="replace"))
                            traces.append(trace)
                        verify_witness(name, *traces, instrument.structural)
                        # The normal comparator fails fast. Independently require
                        # detection under each origin's freshly recorded tape.
                        for recording, peer, tape_label, direction in [
                            (traces[0], mutant_b, "A", "Core record -> CoreB replay"),
                            (traces[1], normal_a, "B", "CoreB record -> Core replay")]:
                            command = [str(peer), "--runtime", str(runtime), "--input", str(cabs),
                                "--fuel", str(options.fuel), "--address-space-top", str(0xFFFFFFFFFFFF),
                                "--core-build", sha256(normal_a), "--coreb-build", sha256(mutant_b),
                                "--mode", "replay", "--tape", str(worktree / f".tmp/{tape_label}.json")]
                            code, output, error = instrument.run_child(command, options.timeout, 4096 * 1024**2, 16 * 1024**2)
                            try:
                                replay = instrument.parse_trace(output, replay=True)
                                if code != 0:
                                    raise RuntimeError(f"{name}: {direction} exited {code} despite complete output")
                                instrument.compare(recording, replay, direction)
                            except instrument.Mismatch:
                                pass  # This is the required comparator verdict.
                            else:
                                raise RuntimeError(f"{name}: mutation was not detected in {direction}")
                            diagnostics(f"{name} {direction} stderr", error.decode("utf-8", errors="replace"))
                    if mutation.artifact:
                        pair = worktree / "lean_frontend/.lake/build/bin/coreb-pair-check"
                        code, output, error = instrument.run_child(
                            [str(pair), str(runtime), str(cabs), str(options.fuel), str(0xFFFFFFFFFFFF), "16"],
                            options.timeout, 4096 * 1024**2, 16 * 1024**2)
                        diagnostics(f"{name} artifact checker stderr", error.decode("utf-8", errors="replace"))
                        rows = [json.loads(line) for line in output.splitlines() if line.strip()]
                        artifact = (code == 2 and len(rows) == 1 and rows[0].get("paired-check") == "failed"
                                    and "complete Core/CoreB artifact differs" in rows[0].get("reason", ""))
                        if not artifact:
                            raise RuntimeError(f"{name}: paired artifact mutation was not detected\n{output}\n{error}")
                    result = {"mutant": name, "detected": True, "verdict": mutation.verdict,
                              "artifact": artifact, "source": revision,
                              "replay_directions": 1 if mutation.verdict == "panic" else 2,
                              "reverse_applicable": mutation.verdict != "panic"}
                    results.append(result)
                    print(json.dumps(result, sort_keys=True), flush=True)
                finally:
                    if added:
                        git(source, "worktree", "remove", "--force", str(worktree))
    finally:
        if (sha256(normal_a), sha256(normal_b)) != original_hashes:
            raise RuntimeError("normal Core/CoreB binaries changed during mutation campaign")
    print(json.dumps({"mutation-campaign": "passed", "count": len(results), "source": revision}, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"MUTATION_CAMPAIGN_FAILED: {error}", file=sys.stderr)
        sys.exit(1)
