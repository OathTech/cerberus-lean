#!/usr/bin/env python3
"""Check normalized-AIL breakpoint phases against completed C effects.

--root supplies the comparator and warm binaries; fixtures belong to this
script's checkout. Every fixture records/replays Core and resumed Nice in both
directions. Output markers follow the effects they describe. A phase assertion
checks the exact accumulated stdout at the actual pause, not only final output
or a role count. No heap or continuation is serialized.
"""
import argparse
from collections import defaultdict
from dataclasses import dataclass
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
CONDITION = "condition-ready"
RESTART = "while-restart-pending"
DO_CONDITION = "do-condition-pending"
PHASES = (CONDITION, RESTART, DO_CONDITION)


@dataclass(frozen=True)
class Case:
    name: str
    output: str
    condition: tuple[str, ...] = ()
    restart: tuple[str, ...] = ()
    do_condition: tuple[str, ...] = ()
    kind: str = "defined"


CASES = (
    Case("while_normal", "T1B1T2B2T3", ("T1", "T1B1T2", "T1B1T2B2T3"),
         ("T1B1", "T1B1T2B2")),
    Case("while_continue", "T1B1T2B2T3", ("T1", "T1B1T2", "T1B1T2B2T3"),
         ("T1B1", "T1B1T2B2")),
    Case("do_normal", "B1T1B2T2", do_condition=("B1", "B1T1B2")),
    Case("do_continue", "B1T1B2T2", do_condition=("B1", "B1T1B2")),
    Case("for_normal", "T1B1I1T2B2I2T3", ("T1", "T1B1I1T2", "T1B1I1T2B2I2T3"),
         ("T1B1I1", "T1B1I1T2B2I2")),
    Case("for_continue", "T1B1I1T2B2I2T3", ("T1", "T1B1I1T2", "T1B1I1T2B2I2T3"),
         ("T1B1I1", "T1B1I1T2B2I2")),
    Case("breaks", "WABFC", ("W", "WABF")),
    Case("do_return", "R"),
    Case("while_false", "F", ("F",)),
    Case("goto_entry", "L0T0B1L1T1B2L2T2",
         ("L0T0", "L0T0B1L1T1", "L0T0B1L1T1B2L2T2"),
         ("L0", "L0T0B1L1", "L0T0B1L1T1B2L2")),
    Case("do_condition_ub", "B", do_condition=("B",), kind="undefined"),
    Case("while_condition_ub", "G", kind="undefined"),
    Case("for_increment_ub", "TBI", ("T",), kind="undefined"),
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def returned_integer(trace):
    value = trace.outcome["result"]["value"]
    for tag in ("Vloaded", "LVspecified", "OVinteger"):
        require(isinstance(value, dict) and value.get("tag") == tag and
                len(value.get("fields", [])) == 1, f"expected integer result: {tag}")
        value = value["fields"][0]
    require(isinstance(value, dict) and set(value) == {"IV"} and
            value["IV"].get("prov") == "Prov_none", "unexpected result provenance")
    return value["IV"]["val_"]


def check_outcome(case, trace):
    require(trace.end["kind"] == case.kind, f"{case.name}: wrong outcome kind")
    result = trace.outcome["result"] if case.kind == "defined" else trace.outcome
    require(result["stdout"] == case.output and result["stderr"] == "",
            f"{case.name}: unexpected final output")
    if case.kind == "defined":
        require(not result["blocked"] and returned_integer(trace) == 0,
                f"{case.name}: counters failed or execution blocked")


def check_phases(case, trace):
    check_outcome(case, trace)
    output = ""
    observed = defaultdict(list)
    origins = {}
    identities = {}
    count = 0
    for event in trace.events:
        if "observation" in event:
            observation = event["observation"]
            if observation.get("channel") == "stdout":
                output += observation["text"]
        elif event.get("channel") == "nd" and event.get("kind") == "pause":
            point = event["parent"]
            count += 1
            require(point["schema"] == "corenice-breakpoint-v2",
                    f"{case.name}: old breakpoint schema")
            origin = point["origin"]
            require(isinstance(origin, dict) and set(origin) == {"stage", "occurrence", "slot"}
                    and origin["stage"] == "normalized-ail"
                    and all(isinstance(origin[key], int) and not isinstance(origin[key], bool)
                            and origin[key] >= 0 for key in ("occurrence", "slot")),
                    f"{case.name}: generated cut lacks typed normalized-AIL origin")
            require(point["encounter"] == count,
                    f"{case.name}: missing or repeated all-policy encounter")
            role = point["role"]
            require(role in (*PHASES, "normalized-ail-join"),
                    f"{case.name}: unexpected phase role {role}")
            identity = json.dumps([point["procedure"], point["site"]], sort_keys=True)
            provenance = json.dumps([point["procedure"], origin], sort_keys=True)
            descriptor = (provenance, role)
            require(identities.get(identity, descriptor) == descriptor,
                    f"{case.name}: static site changed origin/role across visits")
            require(origins.get(provenance, identity) == identity,
                    f"{case.name}: distinct sites share an occurrence/slot")
            identities[identity] = descriptor
            origins[provenance] = identity
            if role in PHASES:
                observed[role].append(output)
    require(output == case.output, f"{case.name}: observed stdout deltas differ from terminal output")
    for role, expected in zip(PHASES, (case.condition, case.restart, case.do_condition)):
        require(observed[role] == list(expected),
                f"{case.name}: {role} saw prefixes {observed[role]!r}; expected {list(expected)!r}")
    return count, sum(len(observed[role]) for role in PHASES)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--root", type=Path, default=ROOT,
                        help="provisioned checkout supplying comparator and binaries")
    parser.add_argument("--case", action="append", choices=[case.name for case in CASES])
    parser.add_argument("--fuel", type=int, default=1000000)
    parser.add_argument("--timeout", type=float, default=30.0)
    options = parser.parse_args(argv)
    root = options.root.resolve(strict=True)
    spec = importlib.util.spec_from_file_location("corenice_phase_diff", root / "scripts/corenice-diff.py")
    diff = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = diff
    spec.loader.exec_module(diff)
    try:
        core = (root / "lean_frontend/.lake/build/bin/core-diff").resolve(strict=True)
        nice = (root / "lean_frontend/.lake/build/bin/corenice-resume").resolve(strict=True)
        frozen = {binary: diff.sha256(binary) for binary in (core, nice)}
        cases = [case for case in CASES if options.case is None or case.name in options.case]
        total_pauses = total_phases = 0
        for case in cases:
            config = diff.parse_options([
                str(ROOT / "tests/corenice/phases" / (case.name + ".c")),
                "--core-bin", str(core), "--corenice-bin", str(nice),
                "--comparison", "breakpoints", "--fuel", str(options.fuel),
                "--timeout", str(options.timeout),
                "--corenice-arg=--pause-policy", "--corenice-arg=all"])
            counts = []
            summary = diff.compare_case(config, (frozen[core], frozen[nice]),
                inspect=lambda trace: check_outcome(case, trace),
                inspect_nice=lambda trace: counts.append(check_phases(case, trace)))
            require(summary["indices"] == [], f"{case.name}: unexpected genuine choices")
            require(len(counts) == 1, f"{case.name}: phase inspection did not run once")
            pauses, phases = counts[0]
            total_pauses += pauses
            total_phases += phases
            print(f"PASS: {case.name}: {case.kind}, {phases} exact phase prefixes, "
                  f"{pauses} actual pauses; both recording directions", flush=True)
        require(all(diff.sha256(binary) == digest for binary, digest in frozen.items()),
                "a compared binary changed during the phase checks")
        print(f"PASS: {len(cases)} bidirectional comparisons ({4 * len(cases)} interpreter executions), "
              f"{total_phases} checked loop/condition phases, {total_pauses} all-policy pauses")
        print("LIMIT: bounded normalized-AIL phase witnesses; not source-C provenance or a simulation theorem")
    except (diff.Incomplete, diff.Mismatch, OSError, ValueError, KeyError, TypeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
