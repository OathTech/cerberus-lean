#!/usr/bin/env python3
"""Finite differential checks and bounded progress probes for saturated CoreNice.

An incomplete divergent probe is never accepted as equivalence. It checks only
that successive finite prefixes keep reaching cuts without faults. Complete
cases use the existing bidirectional choice-tape comparator.
"""
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("corenice_diff", ROOT / "scripts/corenice-diff.py")
diff = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = diff
spec.loader.exec_module(diff)


def require(condition, reason):
    if not condition:
        raise ValueError(reason)


def points(trace):
    return [event["parent"] for event in trace.events
            if event.get("channel") == "nd" and event.get("kind") == "pause"]


def child(command):
    code, output, error = diff.run_child(list(map(str, command)), 40, 4 * 1024**3, 32 * 1024**2)
    require(not error, f"child diagnostics: {diff.stderr_excerpt(error)}")
    return code, output


def main():
    os.environ["LEAN_ABORT_ON_PANIC"] = "1"
    binary = ROOT / "lean_frontend/.lake/build/bin/corenice-saturated"
    core = ROOT / "lean_frontend/.lake/build/bin/core-diff"
    frozen = (diff.sha256(core), diff.sha256(binary))
    producer = ROOT / "_build/default/backend/driver/main.exe"
    runtime = ROOT / "_build/install/default"
    cases = [
        ("tests/corenice/saturation/deep_return.c", None, "defined"),
        ("tests/corenice/saturation/indirect_return.c", None, "defined"),
        ("tests/corenice/saturation/runtime_string.c", None, "defined"),
        ("tests/corenice/breakpoints/composition.c", None, "defined"),
        ("tests/corenice/comesfrom-tightening/jump_into_branch.c", None, "defined"),
        ("tests/corenice/comesfrom-tightening/sequence_suffix.c", None, "defined"),
        ("tests/corenice/breakpoints/ub_before_cut.c", None, "undefined"),
        ("tests/corenice/breakpoints/ub_after_cut.c", None, "undefined"),
        ("tests/corenice/review/duff.c", None, "defined"),
    ] + [("tests/z2-probes/nd/order3.c", f"{first},{second}", "defined")
         for first in range(3) for second in range(2)]
    comparisons = visits = 0
    for path, choices, expected_kind in cases:
        for policy in ("all", "none", "every:2"):
            args = [str(ROOT / path), "--corenice-bin", str(binary), "--comparison", "breakpoints",
                    "--corenice-arg=--pause-policy", f"--corenice-arg={policy}"]
            if choices is not None:
                args += ["--choices", choices]
            options = diff.parse_options(args)

            def inspect(trace):
                cuts = points(trace)
                if policy == "all":
                    require(any(p["role"] == "procedure-entry" for p in cuts), "missing executed entry")
                    if path.endswith("deep_return.c"):
                        require(sum(p["role"] == "call-return" for p in cuts) >= 65,
                                "deep unwind lacked its call-return cuts")
                        require(diff.summarize(trace)["observed_tags"].get("driver:function_return", 0) >= 65,
                                "marked C returns lost original function-return observations")
                    if path.endswith("runtime_string.c"):
                        require(any(p["role"] == "procedure-entry" and
                                    "rev_listFromStr_aux" in json.dumps(p["procedure"]) for p in cuts),
                                "runtime recursive helper was not covered")
                if policy == "none":
                    require(not cuts, "none policy emitted host pauses")

            result = diff.compare_case(options, build_pair=frozen, inspect_nice=inspect)
            require(result["kind"] == expected_kind,
                    f"{path}: expected {expected_kind}, got {result['kind']}")
            comparisons += 1
            visits += result["breakpoint_visits"]
            print(f"PASS: {Path(path).name} choices={choices or 'first'} policy={policy}", flush=True)

    prefixes = 0
    with tempfile.TemporaryDirectory(prefix="saturation-progress-", dir=ROOT / ".tmp") as temporary:
        directory = Path(temporary)
        for name, role in [("goto_cycle", "label-entry"), ("mutual_goto", "label-entry"),
                           ("goto_inside_loop", "label-entry"), ("recursive_cycle", "procedure-entry"),
                           ("mutual_recursion", "procedure-entry"), ("indirect_recursion", "procedure-entry")]:
            code, cabs = child([producer, f"--runtime={runtime}", "--cabs-json",
                                ROOT / f"tests/corenice/saturation/{name}.c"])
            require(code == 0, f"producer failed for {name}")
            input_path = directory / f"{name}.json"
            input_path.write_bytes(cabs)
            previous = 0
            for fuel in (1000, 2000):
                code, output = child([binary, "--runtime", runtime, "--input", input_path,
                    "--mode", "record", "--tape", directory / "prefix.tape.json", "--fuel", str(fuel),
                    "--address-space-top", "4294967295", "--core-build", frozen[0],
                    "--corenice-build", frozen[1], "--pause-policy", "all"])
                rows = [json.loads(line) for line in output.splitlines()]
                require(code == 2 and rows[-1].get("complete") is False, "expected incomplete bounded prefix")
                outcomes = [row["outcome"] for row in rows if row.get("record") == "outcome"]
                require(len(outcomes) == 1 and outcomes[0]["kind"] == "incomplete" and
                        outcomes[0]["reason"] in {"breakpoint driver budget exhausted", "ND traversal fuel exhausted"},
                        f"{name}: unexpected failure instead of continuing cut progress: {outcomes}")
                cuts = [row["event"]["parent"] for row in rows if row.get("record") == "event" and
                        row["event"].get("kind") == "pause"]
                count = sum(point["role"] == role for point in cuts)
                require(count > max(previous, 2), f"{name}: no repeated/increasing {role} progress")
                require(all(a["driverSteps"] < b["driverSteps"] for a, b in zip(cuts, cuts[1:])),
                        f"{name}: pause did not advance actual execution")
                previous = count
                prefixes += 1
                print(f"OBSERVED PREFIX: {name} budget={fuel} {role}={count}; incomplete, not equivalence", flush=True)
    require(frozen == (diff.sha256(core), diff.sha256(binary)), "binaries changed during the run")
    print(json.dumps({"complete_bidirectional_comparisons": comparisons, "executions": comparisons * 4,
                      "pauses": visits, "incomplete_progress_probes": prefixes,
                      "universal_saturation_theorem": "not established"}))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, diff.Incomplete, diff.Mismatch) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
