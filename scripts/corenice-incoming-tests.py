#!/usr/bin/env python3
"""Focused actual-rule controls and bidirectional C/CoreNice fixture comparisons.

Build corenice-incoming-tests, core-diff and corenice-diff first. Arguments after
--unit-bin are ordinary corenice-diff path/resource flags. Fixture comparisons
use exact traces. Generated-C metadata corruption is a separate campaign;
ordinary traces do not report how many optimized jump checks ran.
"""
import argparse
import importlib.util
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("corenice_diff", ROOT / "scripts/corenice-diff.py")
diff = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = diff
spec.loader.exec_module(diff)


def run_unit_controls(binary):
    # Unknown-label controls intentionally exercise the existing native panic;
    # the normal suite must complete cleanly before either control is attempted.
    os.environ["LEAN_ABORT_ON_PANIC"] = "1"
    code, stdout, stderr = diff.run_child([str(binary)], 30, 4096 * 1024**2, 1024**2)
    if code != 0 or stderr:
        raise ValueError(f"actual-rule tests failed ({code}): {diff.stderr_excerpt(stderr)}")
    text = stdout.decode("utf-8")
    for rule in ("core_run", "core_reduction"):
        if f"PASS: {rule}: 12 actual transitions" not in text:
            raise ValueError(f"actual-rule test did not attest {rule}")
    if "PASS: optimized argument UB positive control" not in text:
        raise ValueError("missing argument-evaluation positive control")
    print(text, end="")
    for mode in ("legacy", "optimized"):
        code, stdout, stderr = diff.run_child(
            [str(binary), f"--unknown-label-{mode}"], 30, 4096 * 1024**2, 1024**2)
        if code == 0 or b"Erun couldn't resolve label:" not in stderr:
            raise ValueError(f"{mode}: missing original unresolved-label failure: "
                             f"exit={code}; {diff.stderr_excerpt(stderr)}")
        if b"unknown label became NiceFault" in stderr or stdout:
            raise ValueError(f"{mode}: unexpected output from unresolved-label control")
        print(f"PASS: {mode}: original unresolved-label failure precedes incoming check")


def expected_result(trace):
    if trace.end["kind"] != "defined":
        raise ValueError(f"fixture did not complete defined: {trace.end['kind']}")
    result = trace.outcome["result"]
    if result["blocked"] or result["stdout"] or result["stderr"]:
        raise ValueError("unexpected fixture output or blocked result")
    value = result["value"]
    for tag in ("Vloaded", "LVspecified", "OVinteger"):
        if value.get("tag") != tag or len(value.get("fields", [])) != 1:
            raise ValueError(f"fixture result does not have the expected {tag} shape")
        value = value["fields"][0]
    if value != {"IV": {"prov": "Prov_none", "val_": 0}}:
        raise ValueError(f"fixture returned failure: {value}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--unit-bin", type=Path,
                        default=ROOT / "lean_frontend/.lake/build/bin/corenice-incoming-tests")
    options, flags = parser.parse_known_args()
    run_unit_controls(options.unit_bin.resolve(strict=True))
    cases = sorted((ROOT / "tests/corenice/comesfrom").glob("*.c"))
    if not cases:
        raise ValueError("missing comesfrom C fixtures")
    comparisons = 0
    for source in cases:
        choices = [0, 1] if source.stem == "choice_order" else [None]
        for choice in choices:
            policy = [] if choice is None else ["--choices", str(choice)]
            config = diff.parse_options([str(source), *flags, *policy])
            if config.comparison != "exact":
                raise ValueError("comesfrom fixtures require exact trace comparison")
            result = diff.compare_case(config, inspect=expected_result)
            comparisons += 1
            print(f"PASS: {source.name}: choice-prefix={choice}, "
                  f"genuine-choices={len(result['indices'])}, both directions")
    print(f"PASS: {len(cases)} C fixtures, {comparisons} exact bidirectional comparisons; "
          "25 actual-rule transitions, 2 original-error precedence controls")
    print("NOT MEASURED here: generated-program checked-jump counts; "
          "use post-finalization metadata corruption to establish those paths")


if __name__ == "__main__":
    try:
        main()
    except (diff.Incomplete, diff.Mismatch, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
