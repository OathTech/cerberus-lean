#!/usr/bin/env python3
"""Run all non-libc minimal inputs through the bidirectional Core/Nice comparator.

Comparator flags are forwarded. The two existing allocator-exhaustion fixtures
are separate expected-error controls, accepted only for their exact outcome.
Other model errors, incomplete runs and mismatches fail the report.
"""
from collections import Counter
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("corenice_minimal_diff", ROOT / "scripts/corenice-diff.py")
diff = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = diff
spec.loader.exec_module(diff)

EXPECTED_OOM = {
    "112-allocator-exhausted-single-request.c",
    "113-allocator-exhausted-single-request-overlap.c",
}
OOM_OUTCOME = {
    "kind": "model-error", "stdout": "", "stderr": "",
    "reason": {"kind": "other", "error": {
        "DErr_memory": {"MerrOther": "Concrete.allocator: failed (out of memory)"}}},
}


def main():
    paths = sorted(path for path in (ROOT / "tests/minimal").glob("*.c")
                   if not path.name.endswith(".libc.c"))
    if not paths or not EXPECTED_OOM <= {path.name for path in paths}:
        raise ValueError("minimal corpus or expected OOM fixtures missing")
    report = {"inputs": len(paths), "outcomes": Counter(), "breakpoint_visits": 0,
              "breakpoint_roles": Counter(), "failures": []}
    builds = None
    hashes = {}
    for path in paths:
        options = diff.parse_options([str(path), *sys.argv[1:]])
        if builds is None:
            hashes = {binary: diff.sha256(binary) for binary in
                      (options.core_bin, options.corenice_bin, options.producer.resolve())}
            builds = (hashes[options.core_bin], hashes[options.corenice_bin])

        def inspect(trace):
            if path.name in EXPECTED_OOM:
                if trace.outcome != OOM_OUTCOME:
                    raise ValueError("expected allocator OOM outcome changed")
            elif trace.end["kind"] not in {"defined", "undefined"}:
                raise ValueError("unexpected model error")

        try:
            summary = diff.compare_case(options, builds, inspect=inspect)
            kind = "expected-oom-control" if path.name in EXPECTED_OOM else summary["kind"]
            report["outcomes"][kind] += 1
            report["breakpoint_visits"] += summary["breakpoint_visits"]
            report["breakpoint_roles"].update(summary["breakpoint_roles"])
        except (diff.Mismatch, diff.Incomplete, OSError, ValueError) as error:
            report["failures"].append({"input": path.name, "reason": str(error)[:2000]})
    if any(diff.sha256(path) != digest for path, digest in hashes.items()):
        raise ValueError("minimal campaign executable changed while running")
    print(json.dumps(report, sort_keys=True, indent=2))
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
