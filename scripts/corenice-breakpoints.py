#!/usr/bin/env python3
"""Focused Core/CoreNice breakpoint comparisons and executed pause-policy checks.

Build core-diff, corenice-diff and corenice-resume first. --root selects a
provisioned owned checkout and its comparison module/binaries; fixtures remain
relative to this script's checkout. Every comparison records/replays in both
directions. No model errors, incomplete runs or unexpected faults are accepted.
"""
import argparse
from collections import Counter
from dataclasses import dataclass
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Case:
    name: str
    path: str
    value: int | None = 0
    kind: str = "defined"
    outputs: tuple[str, ...] = ("",)
    choices: tuple[str | None, ...] = (None,)
    roles: tuple[str, ...] = ("statement-join",)
    repeated: bool = False
    no_pauses: bool = False
    genuine_choice: bool = False
    enumerate_subsets: bool = False


CASES = (
    Case("two-cuts", "tests/corenice/breakpoints/two_cuts.c", value=3, enumerate_subsets=True),
    Case("composition", "tests/corenice/breakpoints/composition.c", value=6,
         roles=("statement-join", "condition-ready", "loop-body-done"), repeated=True),
    Case("do-loop", "tests/corenice/breakpoints/do_loop.c",
         roles=("statement-join", "loop-body-done"), repeated=True),
    Case("abrupt-return", "tests/corenice/breakpoints/abrupt_return.c", value=7,
         roles=(), no_pauses=True),
    Case("goto-skip", "tests/corenice/breakpoints/goto_skip.c", roles=(), no_pauses=True),
    Case("suffix-entry", "tests/corenice/comesfrom-tightening/sequence_suffix.c"),
    Case("branch-entry", "tests/corenice/comesfrom-tightening/jump_into_branch.c"),
    Case("break-continue", "tests/corenice/comesfrom/loops_break_continue.c",
         roles=("statement-join", "condition-ready", "loop-body-done"), repeated=True),
    Case("recursive-goto", "tests/corenice/comesfrom/recursive_goto.c",
         roles=("statement-join", "condition-ready"), repeated=True),
    Case("sibling-calls", "tests/corenice/breakpoints/sibling_calls.c",
         outputs=("LR\n", "RL\n"), choices=("0", "1,1,1"), genuine_choice=True),
    Case("ub-before", "tests/corenice/breakpoints/ub_before_cut.c", value=None,
         kind="undefined", roles=(), no_pauses=True),
    Case("ub-after", "tests/corenice/breakpoints/ub_after_cut.c", value=None,
         kind="undefined"),
    Case("output-before-ub", "tests/corenice/fixtures/output_before_ub.c", value=None,
         kind="undefined", outputs=("before UB\n",)),
    Case("minimal-recursive", "tests/minimal/017-func-recursive.c", value=120,
         roles=("condition-ready",), repeated=True),
    Case("minimal-for", "tests/minimal/027-for-loop.c", value=15,
         roles=("statement-join", "condition-ready", "loop-body-done"), repeated=True),
    Case("minimal-goto", "tests/minimal/061-goto.c", value=1),
)


def check(condition, message):
    if not condition:
        raise ValueError(message)


def returned_integer(trace):
    value = trace.outcome["result"]["value"]
    for tag in ("Vloaded", "LVspecified", "OVinteger"):
        check(isinstance(value, dict) and value.get("tag") == tag and
              len(value.get("fields", [])) == 1, f"expected integer result in {tag} form")
        value = value["fields"][0]
    check(isinstance(value, dict) and set(value) == {"IV"} and
          value["IV"].get("prov") == "Prov_none", "unexpected integer provenance/result")
    return value["IV"]["val_"]


def pause_points(trace):
    return [event["parent"] for event in trace.events
            if event.get("channel") == "nd" and event.get("kind") == "pause"]


def site_key(point):
    return json.dumps([point["procedure"], point["site"]], sort_keys=True)


def check_outcome(case, trace):
    check(trace.end["kind"] == case.kind,
          f"{case.name}: expected {case.kind}, observed {trace.end['kind']}")
    terminal = trace.outcome["result"] if case.kind == "defined" else trace.outcome
    check(terminal["stdout"] in case.outputs and terminal["stderr"] == "",
          f"{case.name}: unexpected terminal output")
    if case.kind == "defined":
        check(not terminal["blocked"] and returned_integer(trace) == case.value,
              f"{case.name}: incorrect result or blocked execution")
    deltas = [event["observation"] for event in trace.events if "observation" in event]
    output = "".join(delta["text"] for delta in deltas if delta["channel"] == "stdout")
    check(output == terminal["stdout"], f"{case.name}: output deltas dropped or repeated text")
    return terminal["stdout"]


def check_all_points(case, points):
    check(bool(points) != case.no_pauses,
          f"{case.name}: {'unexpected' if case.no_pauses else 'missing'} executed breakpoint")
    check([point["encounter"] for point in points] == list(range(1, len(points) + 1)),
          f"{case.name}: all-policy encounter numbers are not consecutive")
    roles = Counter(point["role"] for point in points)
    for role in case.roles:
        check(roles[role] > 0, f"{case.name}: no executed {role} site")
    if case.repeated:
        check(max(Counter(site_key(point) for point in points).values(), default=0) > 1,
              f"{case.name}: no repeated execution of a static site")
    check(all(point["ailOrigin"] is not None for point in points),
          f"{case.name}: generated source breakpoint lacks AIL provenance")
    for earlier, later in zip(points, points[1:]):
        check(later["driverSteps"] > earlier["driverSteps"],
              f"{case.name}: pause repeated a completed boundary or reset driver accounting")
        check(later["remainingBudget"] < earlier["remainingBudget"],
              f"{case.name}: driver budget was replenished across a pause")


def load_comparator(root):
    path = root / "scripts/corenice-diff.py"
    spec = importlib.util.spec_from_file_location("corenice_breakpoint_diff", path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def parse_options(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--root", type=Path, default=ROOT,
                        help="provisioned owned checkout supplying comparator and default binaries")
    parser.add_argument("--producer", type=Path)
    parser.add_argument("--runtime", type=Path)
    parser.add_argument("--core-bin", type=Path)
    parser.add_argument("--automatic-bin", type=Path)
    parser.add_argument("--resume-bin", type=Path)
    parser.add_argument("--case", action="append", choices=[case.name for case in CASES],
                        help="run selected cases only; repeatable")
    parser.add_argument("--fuel", type=int, default=1000000)
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--memory-mb", type=int, default=4096)
    parser.add_argument("--output-mb", type=int, default=16)
    return parser.parse_args(argv)


def run_suite(options, diff):
    build_root = options.root.resolve(strict=True)
    producer = (options.producer or build_root / "_build/default/backend/driver/main.exe").resolve(strict=True)
    runtime = (options.runtime or build_root / "_build/install/default").resolve(strict=True)
    core = (options.core_bin or build_root / "lean_frontend/.lake/build/bin/core-diff").resolve(strict=True)
    automatic = (options.automatic_bin or build_root / "lean_frontend/.lake/build/bin/corenice-diff").resolve(strict=True)
    resumed = (options.resume_bin or build_root / "lean_frontend/.lake/build/bin/corenice-resume").resolve(strict=True)
    frozen = {path: diff.sha256(path) for path in (core, automatic, resumed)}
    common = ["--producer", str(producer), "--runtime", str(runtime), "--core-bin", str(core),
              "--fuel", str(options.fuel), "--timeout", str(options.timeout),
              "--memory-mb", str(options.memory_mb), "--output-mb", str(options.output_mb)]
    cases = [case for case in CASES if options.case is None or case.name in options.case]
    comparisons = paths = visits = unique_sites = 0
    outcomes = Counter()
    role_visits = Counter()
    outputs = {case.name: set() for case in cases}
    for case in cases:
        source = (ROOT / case.path).resolve(strict=True)
        for choice in case.choices:
            paths += 1
            flags = [] if choice is None else ["--choices", choice]
            config = diff.parse_options([str(source), *common, *flags,
                                         "--corenice-bin", str(automatic), "--comparison", "exact"])
            reference = diff.compare_case(config, (frozen[core], frozen[automatic]),
                inspect=lambda trace: outputs[case.name].add(check_outcome(case, trace)))
            comparisons += 1
            if case.genuine_choice:
                check(len(reference["indices"]) > 0, f"{case.name}: no genuine competing choice")
            all_points = []
            policies = ["all", "none", "every:2"]
            while policies:
                policy = policies.pop(0)
                observed = []
                config = diff.parse_options([str(source), *common, *flags,
                    "--corenice-bin", str(resumed), "--comparison", "breakpoints",
                    "--corenice-arg=--pause-policy", "--corenice-arg=" + policy])
                summary = diff.compare_case(config, (frozen[core], frozen[resumed]),
                    inspect=lambda trace: check_outcome(case, trace),
                    inspect_nice=lambda trace: observed.extend(pause_points(trace)))
                comparisons += 1
                check(summary["indices"] == reference["indices"],
                      f"{case.name}/{policy}: pausing changed the actual choice path")
                if policy == "all":
                    all_points = observed
                    check_all_points(case, all_points)
                    visits += len(all_points)
                    role_visits.update(point["role"] for point in all_points)
                    unique_sites += len({site_key(point) for point in all_points})
                    if all_points:
                        chosen = Counter(point["site"] for point in all_points).most_common(1)[0][0]
                        policies.append(f"site:{chosen}")
                    if case.enumerate_subsets:
                        check(len(all_points) == 2, f"{case.name}: expected exactly two reached cuts")
                        policies.extend("visits:" + ",".join(str(i + 1) for i in range(2)
                                        if mask & (1 << i)) for mask in range(4))
                else:
                    if policy == "none":
                        expected = []
                    elif policy == "every:2":
                        expected = [point for point in all_points if point["encounter"] % 2 == 0]
                    elif policy.startswith("site:"):
                        chosen = int(policy.split(":")[1])
                        expected = [point for point in all_points if point["site"] == chosen]
                    else:
                        selected = {int(n) for n in policy.split(":")[1].split(",") if n}
                        expected = [point for point in all_points if point["encounter"] in selected]
                    check(observed == expected,
                          f"{case.name}/{policy}: observed pauses differ from the selected executed encounters")
                check(summary["breakpoint_visits"] == len(observed),
                      f"{case.name}/{policy}: summary does not count actual pauses")
                print(f"PASS: {case.name}, choices={choice or 'first'}, policy={policy}, "
                      f"pauses={len(observed)}, genuine-choices={len(summary['indices'])}; both directions",
                      flush=True)
            outcomes[case.kind] += 1
            if not all_points:
                print(f"NOT APPLICABLE: {case.name}: no reached site for selected-site policy", flush=True)
        if case.genuine_choice:
            check(outputs[case.name] == set(case.outputs),
                  f"{case.name}: supplied choice prefixes did not exercise both observable call orders")
    check(all(diff.sha256(path) == digest for path, digest in frozen.items()),
          "a compared binary changed during the suite")
    print(f"PASS: {len(cases)} source fixtures, {paths} source/choice-policy runs, "
          f"{comparisons} bidirectional comparisons ({comparisons * 4} interpreter executions)")
    print(f"PASS: paths by outcome={dict(outcomes)}; all-policy recording-lane pauses={visits}, "
          f"sum of reached sites per path={unique_sites}; roles={dict(role_visits)}")
    print("NOT MEASURED here: full C coverage, all nondeterministic traces, all pause subsets beyond the enumerated two-cut fixture, "
          "or a simulation theorem")


def main():
    options = parse_options()
    diff = load_comparator(options.root.resolve(strict=True))
    try:
        run_suite(options, diff)
    except (diff.Incomplete, diff.Mismatch, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
