"""Orchestration for core-quote-test; comparisons execute in Lean.

The driver always runs from the repository root with the canonical relative
runtime spelling. Scratch modules and census traces are disposable. A consumer
can pass --module PATH with --input JSON (repeatable), or --libc --module PATH.
With --libc, --input selects a libc-linked user module; without --input it
checks the standalone library and its pin. Both replay the literal environment. No source positions or literal labels are edited.
"""
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[3]
FRONTEND = ROOT / "lean_frontend"
BIN = FRONTEND / ".lake/build/bin"
RUNTIME = "_build/install/default"
SUPPORT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fuel", type=int, required=True)
    parser.add_argument("--libc", action="store_true")
    parser.add_argument("--switches", choices=["inner_arg_temps"],
                        help="match the driver's complete non-default elaboration switch set")
    parser.add_argument("--module", type=Path)
    parser.add_argument("--input", type=Path, action="append", default=[])
    parser.add_argument("--fixture", action="store_true", help="focused first-fixture development check")
    args = parser.parse_args()
    if args.fuel <= 0 or (args.module and not args.libc and not args.input):
        parser.error("positive fuel and the external module's original inputs are required")
    if args.input and not args.module:
        parser.error("--input requires --module")
    if args.fixture and args.module:
        parser.error("--fixture and --module are separate selections")
    if args.libc and args.fixture:
        parser.error("--libc and --fixture are separate selections")
    gnu_time = None
    if args.libc:
        for name in ("gtime", "time"):
            candidate = shutil.which(name)
            if candidate:
                probe = subprocess.run([candidate, "--version"], capture_output=True, text=True)
                if probe.returncode == 0 and "GNU" in probe.stdout and "time" in probe.stdout.lower():
                    gnu_time = candidate
                    break
        if gnu_time is None:
            parser.error("Core quote prerequisite: GNU time is required for Tier B resource measurements (install time or gtime)")
    (ROOT / ".tmp").mkdir(exist_ok=True)
    scratch = Path(tempfile.mkdtemp(prefix="core-quote-test-", dir=ROOT / ".tmp"))
    env = dict(os.environ, LEAN_ABORT_ON_PANIC="1")
    counts = Counter()
    completed = 0
    success = False
    metadata = []
    switches_term = "[.inner_arg_temps]" if args.switches else "[]"
    switch_report = "-- cerberus-lean switches: " + ("[inner_arg_temps]" if args.switches else "[]")
    libc_name = "libc_inner_arg_temps" if args.switches else "libc"

    def run(label, command, cwd=ROOT, expected=0, extra_env=None):
        start = time.monotonic()
        result = subprocess.run([str(ROOT / "scripts/capped"), *map(str, command)],
                                cwd=cwd, env=env | (extra_env or {}), capture_output=True, text=True)
        (scratch / f"{label}.stdout").write_text(result.stdout)
        (scratch / f"{label}.stderr").write_text(result.stderr)
        if result.returncode != expected:
            raise RuntimeError(f"{label}: exit {result.returncode}, expected {expected}; "
                               f"{time.monotonic() - start:.2f}s\n"
                               f"{result.stdout[:4000]}\n{result.stderr[:4000]}\n"
                               f"Complete diagnostics: {scratch / label}.stdout/.stderr")
        print(f"{label}: exit {result.returncode}, {time.monotonic() - start:.2f}s", flush=True)
        return result

    def cli(label, output, inputs, cwd=ROOT, runtime=RUNTIME, expected=0, mode="tu"):
        command = [BIN / "cerberus-lean", f"--runtime={runtime}", "--fuel", args.fuel]
        if args.switches:
            command += [f"--switches={args.switches}"]
        command += ["--quote-libc" if mode == "libc" else "--quote-core", output]
        if mode in ("libc", "linked"):
            command += ["--libc", ROOT / "tests/libc" / (libc_name + ".core")]
            for path in metadata:
                command += ["--libc-tu", path]
        command += inputs
        result = run(label, command, cwd, expected)
        if expected == 0 and (result.stdout or result.stderr):
            raise RuntimeError(f"{label}: successful quotation was not silent")
        return result

    def lean(label, path, *options, expected=0, plugin=True):
        native = native_args if plugin else []
        command = ["lake", "env", "lean", *native, f"--root={scratch}", *options, path]
        timing = scratch / f"{label}.time"
        if gnu_time and not plugin:
            command = [gnu_time, "-f", "%e seconds; %M KB peak RSS; exit %x", "-o", timing, *command]
        result = run(label, command, FRONTEND, expected,
                     {"LEAN_PATH": str(scratch) + os.pathsep + lean_path})
        if gnu_time and not plugin:
            print(f"{label} resources: " + timing.read_text().strip(), flush=True)
        return result

    def check_source(label, source, tail, mode="tu", negative_syntax=False):
        # One checker import. The literal's actual def and helpers are intact.
        path = scratch / f"{label}.lean"
        path.write_text("import Unit.CoreQuoteTest\n" + source +
                        f'\ncheck_core_comparators quotedCore "{mode}"\n' + tail)
        result = lean(label, path, expected=1 if negative_syntax else 0)
        if negative_syntax and "Core quote comparator mismatch" not in result.stdout:
            raise RuntimeError("comparator mutation did not fail at the syntax check")
        return result

    def roundtrip(label, inputs, external=None, mode="tu"):
        nonlocal completed
        started = time.monotonic()
        literal = scratch / f"{label}Literal.lean"
        if external:
            shutil.copyfile(external, literal)
        else:
            cli(label + "-quote", literal, inputs, mode=mode)
        source = literal.read_text()
        if not source.startswith("import Core_run_aux\n") or source.count("\ndef quotedCore : file core_run_annotation :=") != 1:
            raise RuntimeError("expected a self-contained flag-generated quotedCore module")
        if source.splitlines()[2] != switch_report:
            raise RuntimeError(f"{label}: quotation header does not report the selected switch set")
        # Elaborate the literal alone, then import its .olean into the checker.
        # Thus kernel replay below measures the consumer literal, not test code.
        lean(label + "-elaborate", literal, "-o", literal.with_suffix(".olean"), plugin=False)
        inputs_term = "[" + ", ".join(json.dumps(str(p), ensure_ascii=False) for p in inputs) + "]"
        metadata_term = "[" + ", ".join(json.dumps(str(p), ensure_ascii=False) for p in metadata) + "]"
        checker = scratch / f"{label}Check.lean"
        checker.write_text(f"import CoreQuoteCompare\nimport {label}Literal\n" +
            f'\ncheck_core_comparators quotedCore "{mode}"\n' +
            f"#eval CoreQuoteTest.check {json.dumps(str(ROOT), ensure_ascii=False)} {json.dumps(mode)} {switches_term} {args.fuel} {metadata_term} {inputs_term} quotedCore\n")
        result = lean(label + "-compare", checker)
        rows = [line.removeprefix("CORE_QUOTE_CENSUS ") for line in result.stdout.splitlines()
                if line.startswith("CORE_QUOTE_CENSUS ")]
        if len(rows) != 1:
            raise RuntimeError(f"{label}: missing or duplicate whole-file census")
        counts.update(json.loads(rows[0]))
        completed += 1
        print(f"{label} round trip: {time.monotonic() - started:.2f}s", flush=True)
        return literal

    def replay(label):
        timing = scratch / f"{label}-leanchecker.time"
        run(label + "-kernel-replay", [gnu_time, "-f", "%e seconds; %M KB peak RSS; exit %x",
                                      "-o", timing, "lake", "env", "leanchecker", label + "Literal"],
            FRONTEND, extra_env={"LEAN_PATH": str(scratch) + os.pathsep + lean_path})
        print(label + "Literal leanchecker: " + timing.read_text().strip(), flush=True)

    def convention(literal, inputs, mode):
        # Canonical spelling is unchanged under a different absolute alias.
        alias = scratch / "root-alias"
        if not alias.is_symlink():
            alias.symlink_to(ROOT, target_is_directory=True)
        alias_literal = scratch / f"{mode}Alias.lean"
        try:
            cli(mode + "-alias-quote", alias_literal, inputs, cwd=alias, mode=mode)
            if literal.read_bytes() != alias_literal.read_bytes():
                raise RuntimeError("canonical invocation through a project-root symlink changed literal bytes")
        finally:
            # leanchecker scans module search roots recursively. This alias is
            # inside a root: leaving it for the next replay creates a cycle.
            alias.unlink()
        refused = scratch / f"{mode}Refused.lean"
        result = cli(mode + "-wrong-cwd-refusal", refused, inputs, cwd=FRONTEND,
                     runtime="../_build/install/default", expected=2, mode=mode)
        if "Canonical Core quotation convention" not in result.stderr or refused.exists():
            raise RuntimeError("wrong-cwd invocation must name the convention and write nothing")

    try:
        lean_path = run("lean-path", ["lake", "env", "printenv", "LEAN_PATH"], FRONTEND).stdout.strip()
        # Lake's Unix plugin artifacts leave import-library symbols unresolved.
        # Load its recorded dependencies in order, without guessing package/cache
        # locations. The pinned toolchain's trace schema records linkLibs here.
        support = FRONTEND / ".lake/build/lib/libCoreQuoteCompare.so"
        dependencies, seen = [], set()

        def collect_libraries(path):
            if path in seen:
                return
            seen.add(path)
            trace = json.loads(Path(str(path) + ".trace").read_text())
            if trace["schemaVersion"] != "2025-09-10":
                raise RuntimeError("unrecognized Lake library trace schema")
            libraries = dict(trace["inputs"])["linkLibs"]
            if isinstance(libraries, str):
                # A trace hash leaf has no named child paths in this schema.
                int(libraries, 16)
                libraries = []
            if not isinstance(libraries, list):
                raise RuntimeError("unrecognized Lake linkLibs trace")
            for dependency, _ in libraries:
                collect_libraries(Path(dependency))
            dependencies.append(path)

        collect_libraries(support)
        # Build the existing digest implementation with library-visible exports;
        # the driver object uses hidden visibility. No new native source or seam.
        digest_library = scratch / "digest.so"
        run("digest-runtime", ["lake", "env", "leanc", "-shared", "-fPIC", "-DLEAN_EXPORTING",
                               FRONTEND / "native/md5.c", "-o", digest_library], FRONTEND)
        native_args = [f"--load-dynlib={digest_library}"]
        native_args += [f"--load-dynlib={p}" for p in dependencies if p != support]
        native_args += [f"--plugin={support}=initialize_CerberusLean_CoreQuoteCompare"]
        if args.libc:
            result = run("metadata", [ROOT / "scripts/libc_prep.sh", "--jsons", scratch / "metadata"])
            metadata = [Path(line) for line in result.stdout.splitlines()]
            if len(metadata) != 12 or not all(p.is_file() for p in metadata):
                raise RuntimeError("expected twelve canonical metadata JSONs")
            refused = scratch / "NoUserTU.lean"
            result = cli("libc-no-user-refusal", refused, [], expected=2, mode="linked")
            if "--quote-core with --libc requires a user TU" not in result.stderr or refused.exists():
                raise RuntimeError("library-only --quote-core must refuse by name and write nothing")
            if not args.input:
                literal = roundtrip("Libc", [], args.module, mode="libc")
                digest = hashlib.sha256(literal.read_bytes()).hexdigest()
                pin_name = "core-quote-libc-inner-arg-temps.sha256" if args.switches else "core-quote-libc.sha256"
                pin = (SUPPORT / pin_name).read_text().strip()
                if digest != pin:
                    raise RuntimeError(f"libc literal SHA-256 drift: {digest}, pinned {pin}")
                print(f"libc sha256: {digest}", flush=True)
                replay("Libc")
                convention(literal, [], "libc")
            if not args.module or args.input:
                inputs = ([p.resolve() for p in args.input] if args.module else
                          [ROOT / "tests/fixtures/001-return-literal/cabs.json"])
                literal = roundtrip("Linked", inputs, args.module, mode="linked")
                replay("Linked")
                convention(literal, inputs, "linked")
        elif args.module:
            inputs = [p.resolve() for p in args.input]
            literal = roundtrip("Consumer", inputs, args.module.resolve())
        else:
            fixtures = sorted((ROOT / "tests/fixtures").glob("*/cabs.json"))
            corpus = sorted((FRONTEND / "corpus").glob("*.c"))
            if len(fixtures) != 10 or len(corpus) != 16:
                raise RuntimeError("required-input inventory drift (expected 10 fixtures and 16 corpus C files)")
            for i, fixture in enumerate(fixtures[:1] if args.fixture else fixtures):
                literal = roundtrip(f"Fixture{i}", [fixture])
            inputs = [fixtures[0]]
            # Keep the first fixture for the cwd controls.
            literal = scratch / "Fixture0Literal.lean"
            if not args.fixture:
                def export(path, label):
                    result = run(label + "-export", [ROOT / "_build/default/backend/driver/main.exe",
                        f"--runtime={RUNTIME}", "--nolibc", "--cabs-json", path.relative_to(ROOT)])
                    target = scratch / f"{label}.json"
                    target.write_text(result.stdout)
                    return target
                for i, path in enumerate(corpus):
                    roundtrip(f"Corpus{i}", [export(path, f"Corpus{i}")])
                multi = [export(ROOT / f"tests/multi_tu/basic/tu{i}.c", f"Multi{i}") for i in (1, 2)]
                roundtrip("Multi", multi)
            run("local-controls", [BIN / "core-quote-test", "--local-controls"])
            controls = ["main", "global", "binding", "height", "empty-to-mk", "mk-to-empty", "zero-sign",
                        "positive-zero", "negative-zero", "infinity", "negative-infinity", "long-list", "long-list-order"]
            for i, name in enumerate(controls):
                path = scratch / f"Control{i}Literal.lean"
                run(f"control-{name}-quote", [BIN / "core-quote-test", "--emit-control", name, path])
                source = path.read_text()
                check_source(f"Control{i}", source, f'\n#eval CoreQuoteTest.checkControl "{name}" quotedCore\n')
            source = (scratch / "Control7Literal.lean").read_text()
            old = "(@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1)"
            new = "(@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym)"
            if old not in source:
                raise RuntimeError("same-head comparator mutation found no explicit instance")
            check_source("ComparatorMutation", source.replace(old, new, 1), "", negative_syntax=True)

        if not args.libc:
            convention(literal, inputs, "tu")
        if counts["NaN"] or counts["absolute-position"]:
            raise RuntimeError("required inputs contain a NaN or an absolute position path")
        (scratch / "census.json").write_text(json.dumps(counts, sort_keys=True, indent=2))
        print("CORE_QUOTE_CENSUS_TOTAL " + json.dumps(counts, sort_keys=True), flush=True)
        containers = ("Fmap.", "Pmap.", "Pset.", "List.", "Option.", "Prod.", "Unit.", "Float.", "Pos.")
        print(f"CORE_QUOTE_TOTAL inputs={completed}; model constructors=" +
              str(sum(1 for k in counts if "." in k and not k.startswith(containers))) +
              f"; floating={counts['Float.bits']}; NaN={counts['NaN']}; " +
              f"memory-values={sum(v for k, v in counts.items() if k.startswith('CerbMem.MemValue.'))}; " +
              f"positions={counts['CerbLocation.Pos.mk']}; absolute-paths={counts['absolute-position']}", flush=True)
        print("Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)", flush=True)
        success = True
    finally:
        if success:
            shutil.rmtree(scratch)
        else:
            print(f"Core quote test FAILED; disposable diagnostics: {scratch}", flush=True)


if __name__ == "__main__":
    main()
