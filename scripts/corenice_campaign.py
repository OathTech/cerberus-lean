#!/usr/bin/env python3
"""Bounded generated-C smoke, pilot and frozen Core/CoreNice campaign.

Each path runs both record/replay directions and independent same-policy
recordings. Reports contain compact counts, actual path identities and failure
recipes; ephemeral source, Cabs JSON, tapes and traces are deleted after use.
"""

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import time
from types import SimpleNamespace

from corenice_generate import FEATURES, TEMPLATES, VERSION, generate

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("corenice_diff", ROOT / "scripts/corenice-diff.py")
diff = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = diff
spec.loader.exec_module(diff)


def initial_config(phase):
    count = 16 if phase == "smoke" else 100
    return {
        "schema": 1, "generator": VERSION, "phase": phase,
        "seeds": [1701, 2718, 31415, 65537], "programs": count, "paths_per_program": 2,
        "limits": {"child_seconds": 15, "campaign_seconds": 60 if phase == "smoke" else 300,
                   "memory_mb": 4096, "output_mb": 16, "fuel": 1000000},
        "targets": {"defined_programs": count, "per_feature": count,
                    "nd_programs_with_two_tapes": count},
    }


def validate_config(config):
    if config.get("schema") != 1 or config.get("generator") != VERSION:
        raise ValueError("unsupported manifest schema or generator")
    if config.get("phase") == "campaign":
        generator = ROOT / "scripts/corenice_generate.py"
        if config.get("generator_sha256") != diff.sha256(generator):
            raise ValueError("generator differs from the frozen campaign manifest")
    if config.get("phase") not in {"smoke", "pilot", "campaign"}:
        raise ValueError("manifest needs a named phase")
    if not isinstance(config.get("seeds"), list) or not config["seeds"] or any(
            not diff.natural(seed) for seed in config["seeds"]):
        raise ValueError("manifest seeds must be nonempty natural numbers")
    for name in ["programs", "paths_per_program"]:
        if not diff.natural(config.get(name)) or config[name] == 0:
            raise ValueError(f"invalid manifest {name}")
    if not 2 <= config["paths_per_program"] <= 4:
        raise ValueError("campaign samples two to four paths per input")
    for group in ["limits", "targets"]:
        if not isinstance(config.get(group), dict):
            raise ValueError(f"missing manifest {group}")
        for name, value in config[group].items():
            if not diff.natural(value) or value == 0:
                raise ValueError(f"{group}.{name} must be a positive integer")
    if set(config["limits"]) != {"child_seconds", "campaign_seconds", "memory_mb", "output_mb", "fuel"}:
        raise ValueError("missing or unknown resource limits")
    if set(config["targets"]) != {"defined_programs", "per_feature", "nd_programs_with_two_tapes"}:
        raise ValueError("missing or unknown acceptance targets")


def file_stamp(path):
    status = path.stat()
    return (status.st_dev, status.st_ino, status.st_size, status.st_mtime_ns, status.st_ctime_ns)


def next_prefix(first, number):
    """Select an actual alternative, not a new seed that may repeat a path."""
    if number == 0:
        return []
    if number > len(first["indices"]):
        return None
    position = number - 1
    prefix = first["indices"][:position + 1]
    prefix[position] = (prefix[position] + 1) % first["arities"][position]
    return prefix


def executed_features(program, summary):
    """Required effects support the template's guaranteed-executed structure.

    Each template enters main, initializes/uses globals and locals, executes two
    helper calls and a positive-bound loop containing its conditional and array
    accesses, then performs an explicit pointer read/write. No feature is hidden
    in a possibly dead branch. Completed defined runs must also expose their
    memory effects and two helper returns; missing instrumentation fails loudly.
    """
    tags = summary["observed_tags"]
    for tag, minimum in {"driver:load": 1, "driver:store": 1,
                         "memory:access_receipt": 2, "driver:function_return": 2}.items():
        if tags.get(tag, 0) < minimum:
            raise diff.Incomplete(f"generated input lacks executed effect evidence: {tag}")
    return program.features


def acceptance(report, config):
    target = config["targets"]
    missing = []
    if report["defined_programs"] < target["defined_programs"]:
        missing.append("defined_programs")
    for feature in FEATURES:
        if report["features"].get(feature, 0) < target["per_feature"]:
            missing.append(feature)
    if report["nd_programs_with_two_tapes"] < target["nd_programs_with_two_tapes"]:
        missing.append("nd_programs_with_two_tapes")
    if report["path_classes"].get("model-error", 0):
        missing.append("no_matched_model_errors")
    if report["failures"] or report["unattempted_programs"]:
        missing.append("all_admitted_comparisons_complete_without_mismatch")
    return missing


def run_campaign(config, options):
    validate_config(config)
    started = time.monotonic()
    limits = config["limits"]
    paths = [options.core_bin, options.corenice_bin, options.producer]
    stamps = [file_stamp(path) for path in paths]
    build_pair = (diff.sha256(options.core_bin), diff.sha256(options.corenice_bin))

    def unchanged():
        if [file_stamp(path) for path in paths] != stamps:
            raise diff.Incomplete("campaign binary/producer changed during execution")

    report = {
        "phase": config["phase"], "generator": VERSION,
        "manifest_sha256": hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest(),
        "builds": {"Core": build_pair[0], "CoreNice": build_pair[1], "producer": diff.sha256(options.producer)},
        "attempted_programs": 0, "unattempted_programs": config["programs"],
        "defined_programs": 0, "features": Counter(), "templates": Counter(),
        "nd_programs_with_two_tapes": 0, "distinct_input_tape_pairs": 0,
        "selected_indices": Counter(), "choice_kinds": Counter(), "observed_tags": Counter(),
        "path_classes": Counter(), "failure_classes": Counter(), "failures": [], "nondefined_cases": [],
    }
    sources = set()
    ROOT.joinpath(".tmp").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="corenice-campaign-", dir=ROOT / ".tmp") as temporary:
        source = Path(temporary) / "generated.c"
        for ordinal in range(config["programs"]):
            if time.monotonic() - started >= limits["campaign_seconds"]:
                report["failures"].append({"kind": "incomplete", "category": "campaign-resource",
                                           "reason": "campaign wall limit"})
                report["failure_classes"]["campaign-resource"] += 1
                break
            seed = config["seeds"][ordinal % len(config["seeds"])]
            index = ordinal // len(config["seeds"])
            program = generate(seed, index)
            # Comments (including seed/index) cannot create fake input diversity.
            source_digest = hashlib.sha256(program.source.split("\n", 1)[1].encode()).hexdigest()
            if source_digest in sources:
                raise diff.Incomplete(f"generator repeated a C program: seed={seed}, index={index}")
            sources.add(source_digest)
            source.write_text(program.source)
            report["attempted_programs"] += 1
            report["unattempted_programs"] -= 1
            first, defined, tapes, features = None, [], set(), set()
            for path_number in range(config["paths_per_program"]):
                prefix = [] if first is None else next_prefix(first, path_number)
                if prefix is None:
                    # No invented choices: the frozen ND target will show the shortfall.
                    break
                run = SimpleNamespace(
                    input=source, cabs_json=False, producer=options.producer, runtime=options.runtime,
                    core_bin=options.core_bin, corenice_bin=options.corenice_bin, fuel=limits["fuel"],
                    address_space_top=0xFFFFFFFFFFFF, arg=[], seed=None,
                    choices=",".join(map(str, prefix)), timeout=limits["child_seconds"],
                    memory_mb=limits["memory_mb"], output_mb=limits["output_mb"],
                    deadline=started + limits["campaign_seconds"])
                try:
                    unchanged()
                    summary = diff.compare_case(run, build_pair)
                    unchanged()
                    first = first or summary
                    kind = summary["kind"]
                    if kind == "defined":
                        features.update(executed_features(program, summary))
                        defined.append(summary)
                        tapes.add(summary["tape_sha256"])
                    else:
                        report["nondefined_cases"].append({"seed": seed, "index": index,
                            "choices": prefix, "kind": kind,
                            "outcome_sha256": summary["outcome_sha256"]})
                    report["path_classes"][kind] += 1
                    report["selected_indices"].update(map(str, summary["indices"]))
                    report["choice_kinds"].update(summary["choice_kinds"])
                    report["observed_tags"].update(summary["observed_tags"])
                except (diff.Mismatch, diff.Incomplete, OSError, ValueError) as error:
                    kind = "mismatch" if isinstance(error, diff.Mismatch) else "incomplete"
                    category = (getattr(error, "category", "incomplete") if isinstance(error, diff.Incomplete)
                                else "mismatch" if isinstance(error, diff.Mismatch)
                                else "filesystem" if isinstance(error, OSError) else "harness-input")
                    report["path_classes"][kind] += 1
                    report["failure_classes"][category] += 1
                    report["failures"].append({"seed": seed, "index": index,
                        "choices": prefix, "kind": kind, "category": category, "reason": str(error)[:2500]})
                    # One failing input suffices for diagnosis; continue other inputs
                    # so the completed denominator remains visible.
                    break
            if defined:
                report["defined_programs"] += 1
                report["features"].update(features)
                report["templates"][program.template] += 1
            report["distinct_input_tape_pairs"] += len(tapes)
            if len(tapes) >= 2 and all(item["indices"] and item["both_directions"] for item in defined):
                report["nd_programs_with_two_tapes"] += 1
            if (ordinal + 1) % 25 == 0:
                print(f"{config['phase']}: {ordinal + 1}/{config['programs']} inputs; "
                      f"{report['defined_programs']} defined; {len(report['failures'])} failures", file=sys.stderr)
    unchanged()
    report["seconds"] = round(time.monotonic() - started, 3)
    report["missing_targets"] = acceptance(report, config)
    report["accepted"] = not report["missing_targets"]
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    phase = parser.add_mutually_exclusive_group(required=True)
    phase.add_argument("--smoke", action="store_true")
    phase.add_argument("--pilot", action="store_true")
    phase.add_argument("--manifest", type=Path, help="frozen campaign acceptance manifest")
    parser.add_argument("--producer", type=Path, default=ROOT / "_build/default/backend/driver/main.exe")
    parser.add_argument("--runtime", type=Path, default=ROOT / "_build/install/default")
    parser.add_argument("--core-bin", type=Path, default=ROOT / "lean_frontend/.lake/build/bin/core-diff")
    parser.add_argument("--corenice-bin", type=Path, default=ROOT / "lean_frontend/.lake/build/bin/corenice-diff")
    options = parser.parse_args(argv)
    config = diff.decode(options.manifest.read_text()) if options.manifest else initial_config(
        "smoke" if options.smoke else "pilot")
    for name in ["producer", "runtime", "core_bin", "corenice_bin"]:
        setattr(options, name, getattr(options, name).resolve(strict=True))
    report = run_campaign(config, options)
    print(json.dumps(report, sort_keys=True, indent=2))
    return 0 if report["accepted"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (diff.Incomplete, OSError, ValueError) as error:
        print(f"INCOMPLETE: {error}", file=sys.stderr)
        sys.exit(2)
