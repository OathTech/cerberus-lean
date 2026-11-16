#!/usr/bin/env python3
"""Real effect/output controls using the ordinary bidirectional comparator.

Optional corenice-diff path/resource flags are forwarded to every comparison.
This is intentionally separate from the generated campaign denominators.
"""
import importlib.util
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("corenice_diff", ROOT / "scripts/corenice-diff.py")
diff = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = diff
spec.loader.exec_module(diff)


def check_output(trace, kind, output):
    if trace.end["kind"] != kind:
        raise ValueError(f"expected {kind}, observed {trace.end['kind']}")
    terminal = trace.outcome["result"] if kind == "defined" else trace.outcome
    if terminal["stdout"] != output or terminal["stderr"] != "":
        raise ValueError("terminal output differs from the fixture expectation")
    channels = [e["observation"] for e in trace.events if "observation" in e]
    observed_output = "".join(e["text"] for e in channels if e["channel"] == "stdout")
    if observed_output != output:
        raise ValueError("output deltas lost or duplicated the actual emitted output")
    if not any(e["channel"] == "memory" and e["events"] for e in channels):
        raise ValueError("actual memory receipts were not observed")


def main():
    flags = sys.argv[1:]
    outputs = set()
    for choice in [0, 1]:
        options = diff.parse_options([
            str(ROOT / "tests/corenice/fixtures/output_choices.c"), *flags, "--choices", str(choice)])

        def inspect(trace):
            output = trace.outcome["result"]["stdout"]
            if output not in {"FG\n", "GF\n"}:
                raise ValueError("function-order fixture emitted unexpected output")
            check_output(trace, "defined", output)
            outputs.add(output)

        diff.compare_case(options, inspect=inspect)
    if outputs != {"FG\n", "GF\n"}:
        raise ValueError("distinct genuine choices did not exercise both output orders")
    options = diff.parse_options([str(ROOT / "tests/corenice/fixtures/output_before_ub.c"), *flags])
    diff.compare_case(options, inspect=lambda trace: check_output(trace, "undefined", "before UB\n"))
    print("PASS: both output orders and failure-state output, each compared in both directions")


if __name__ == "__main__":
    try:
        main()
    except (diff.Incomplete, diff.Mismatch, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
