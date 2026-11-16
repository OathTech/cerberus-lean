#!/usr/bin/env python3
"""Exact Core/CoreNice tightening campaign with executed tightened-label controls.

Defaults to 80 candidates: eight authored fixtures and 72 generated bounded
parameter/control-depth variants. Exact source-text deduplication preserves
the first candidate, giving 73 unique inputs and seven skipped duplicates.
These are bounded structural variants, not uniformly random C. Ordinary
corenice-diff path/resource flags are forwarded. The CoreNice binary must use
the tightening policy. Raw inputs and traces are temporary; output is one
compact JSON record per executed input plus totals.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("incoming_tests", ROOT / "scripts/corenice-incoming-tests.py")
focused = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = focused
spec.loader.exec_module(focused)
diff = focused.diff

FAMILIES = (
    "dead_after_goto", "dead_after_return", "jump_into_branch", "sequence_suffix",
    "goto_backedge", "loop_break_continue", "constant_if", "fallthrough_labels",
)
UNCHANGED = {"constant_if", "fallthrough_labels"}


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f"fixture template changed: expected exactly one {old!r}")
    return text.replace(old, new, 1)


def variant(family, text, index):
    """Change bounded values, dead-edge multiplicity or reconstructed suffix depth."""
    if family in {"dead_after_goto", "dead_after_return"}:
        text = replace_once(text, "goto unused;", "\n  ".join(["goto unused;"] * (1 + index % 4)))
        return replace_once(text, "return 47;", f"return {97 + index};")
    if family == "jump_into_branch":
        text = replace_once(text, "value = 3u;", f"value = {index + 2}u;")
        return replace_once(text, "value - 3u", f"value - {index + 2}u")
    if family == "sequence_suffix":
        start, step, count = index + 1, index + 2, 1 + index % 4
        text = replace_once(text, "value = 1u;", f"value = {start}u;")
        text = replace_once(text, "value = value + 2u;",
                            "\n  ".join([f"value = value + {step}u;"] * count))
        return replace_once(text, "value - 3u", f"value - {start + step * count}u")
    if family == "goto_backedge":
        text = replace_once(text, "count < 4u", f"count < {index + 2}u")
        return replace_once(text, "count - 4u", f"count - {index + 2}u")
    if family == "loop_break_continue":
        skip = 2 + index % 3
        stop = skip + 2 + index % 2
        total = sum(n for n in range(1, stop) if n != skip)
        text = replace_once(text, "count < 5u", f"count < {stop + 1}u")
        text = replace_once(text, "count == 4u", f"count == {stop}u")
        text = replace_once(text, "count == 2u", f"count == {skip}u")
        return replace_once(text, "total - 4u", f"total - {total}u")
    if family == "constant_if":
        return replace_once(text, "return 47;", f"return {97 + index};")
    if family == "fallthrough_labels":
        start, step = index + 1, index + 2
        text = replace_once(text, "value = 1u;", f"value = {start}u;")
        text = replace_once(text, "value = value + 2u;", f"value = value + {step}u;")
        return replace_once(text, "value - 3u", f"value - {start + step}u")
    raise ValueError(f"unknown variant family {family}")


def choice_variant(index):
    left, right = index + 1, index + 3
    return f"""unsigned left_state;
unsigned right_state;
int left(void) {{
  goto entry;
  return 97;
entry:
  left_state = {left}u;
  return (int)left_state;
}}
int right(void) {{
  goto entry;
  return 98;
entry:
  right_state = {right}u;
  return (int)right_state;
}}
int main(void) {{
  int sum = left() + right();
  return sum - {left + right};
}}
"""


def cases(fixtures, generated, variants):
    result = []
    for family in FAMILIES:
        source = fixtures / (family + ".c")
        text = source.read_text()
        result.append((family, "authored", source))
        for index in range(variants):
            path = generated / f"{family}_{index:02}.c"
            path.write_text(variant(family, text, index))
            result.append((family, f"variant-{index}", path))
    for index in range(variants):
        path = generated / f"choice_dead_control_{index:02}.c"
        path.write_text(choice_variant(index))
        result.append(("choice_dead_control", f"variant-{index}", path))
    return result


def deduplicate_cases(candidates):
    """Preserve the first identical source text; authored cases precede variants."""
    seen, unique = set(), []
    for candidate in candidates:
        source_text = candidate[2].read_text()
        if source_text not in seen:
            seen.add(source_text)
            unique.append(candidate)
    return unique, len(candidates) - len(unique)


def generated_control(binary, cabs, config, policy, selection):
    command = [str(binary), str(config.runtime), str(cabs), str(config.fuel),
               str(config.address_space_top), policy, selection]
    code, stdout, stderr = diff.run_child(command, config.timeout,
                                         config.memory_mb * 1024**2, config.output_mb * 1024**2)
    if code != 0 or stderr:
        raise ValueError(f"{selection} control failed ({code}): {diff.stderr_excerpt(stdout)}; "
                         f"{diff.stderr_excerpt(stderr)}")
    result = diff.decode(stdout.decode("utf-8"))
    if result.get("selection") != selection:
        raise ValueError("control binary did not attest requested label selection")
    return result


def run_case(binary, family, source, flags, cabs, build_pair):
    base = diff.parse_options([str(source), *flags])
    if base.comparison != "exact":
        raise ValueError("tightening campaign requires exact comparison")
    code, stdout, stderr = diff.run_child(
        [str(base.producer.resolve(strict=True)), "--runtime=" + str(base.runtime),
         "--cabs-json", str(source)], base.timeout, base.memory_mb * 1024**2, base.output_mb * 1024**2)
    if code != 0:
        raise ValueError(f"Cabs producer failed ({code}): {diff.stderr_excerpt(stderr)}")
    if stderr:
        print("PRODUCER_STDERR: " + diff.stderr_excerpt(stderr), file=sys.stderr)
    cabs.write_bytes(stdout)
    summaries, stats, used_policies, witnesses = [], None, [], 0
    policies = [(["--seed", "0"], "0")]
    for policy_flags, control_policy in policies:
        config = diff.parse_options([str(cabs), *flags, "--cabs-json", *policy_flags])
        summary = diff.compare_case(config, build_pair=build_pair, inspect=focused.expected_result)
        summaries.append(summary)
        used_policies.append(control_policy)
        if len(summaries) == 1 and summary["indices"]:
            # Flip an actual recorded first branch, so this is a genuine
            # alternative rather than another seed that may pick the same tape.
            alternate = (summary["indices"][0] + 1) % summary["arities"][0]
            policies.append((["--choices", str(alternate)], f"prefix:{alternate}"))
        ordinary = generated_control(binary, cabs, config, control_policy, "all")
        tightened = generated_control(binary, cabs, config, control_policy, "tightened")
        if ordinary["incoming-control"] != "passed" or ordinary["typedFaultControls"] != 3:
            raise ValueError("ordinary jump controls did not execute three typed faults")
        current = ordinary["annotationStats"]
        if current != tightened["annotationStats"] or (stats is not None and current != stats):
            raise ValueError("finalized annotation statistics depend on tape/control selection")
        stats = current
        if current["syntacticJumps"] < current["permittedOrigins"]:
            raise ValueError("negative annotation reduction count")
        if current["removedOrigins"] != current["syntacticJumps"] - current["permittedOrigins"]:
            raise ValueError("annotation reduction totals disagree")
        if family in UNCHANGED:
            if current["removedOrigins"] != 0 or current["affectedLabels"] != 0:
                raise ValueError(f"{family}: conservative precision control was unexpectedly tightened")
            if tightened["incoming-control"] != "no-executed-tightened-label":
                raise ValueError(f"{family}: unchanged control claimed an executed tightened label")
        else:
            if current["removedOrigins"] == 0 or current["affectedLabels"] == 0:
                raise ValueError(f"{family}: designated positive case removed no incoming origins")
            if (tightened["incoming-control"] != "passed" or
                    tightened["executedFirstSiteWitnesses"] != 1 or tightened["typedFaultControls"] != 3):
                raise ValueError(f"{family}: no actually executed tightened destination")
            witnesses += 1
        if ordinary["runtimeSyntacticJumps"] != tightened["runtimeSyntacticJumps"]:
            raise ValueError("runtime site inventory changed between controls")
    distinct_tapes = len({tuple(s["indices"]) for s in summaries})
    if len(summaries) == 2 and distinct_tapes != 2:
        raise ValueError("alternate choice prefix did not produce a distinct actual tape")
    if family == "choice_dead_control" and distinct_tapes < 2:
        raise ValueError("function-order family did not exercise distinct genuine choice tapes")
    return {"policies": used_policies, "distinctActualTapes": distinct_tapes,
            "comparisons": len(summaries), "annotationStats": stats,
            "genuineChoices": [len(s["indices"]) for s in summaries],
            "executedTightenedDestinations": witnesses,
            "typedFaultControls": 3 * (len(summaries) + witnesses),
            "runtimeSyntacticJumps": ordinary["runtimeSyntacticJumps"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--fixtures", type=Path, default=ROOT / "tests/corenice/comesfrom-tightening")
    parser.add_argument("--variants", type=int, default=8, help="bounded variants per family (default 8)")
    parser.add_argument("--control-bin", type=Path,
                        default=ROOT / "lean_frontend/.lake/build/bin/corenice-incoming-control")
    options, flags = parser.parse_known_args()
    if not 1 <= options.variants <= 16:
        parser.error("--variants must lie in 1..16")
    if any(flag.split("=", 1)[0] in {"--seed", "--choices", "--cabs-json", "--arg"} for flag in flags):
        parser.error("choice policies, Cabs conversion and argv are fixed by this campaign")
    binary = options.control_bin.resolve(strict=True)
    config = diff.parse_options([str(options.fixtures / "dead_after_goto.c"), *flags])
    binaries = [config.core_bin, config.corenice_bin, binary]
    digests = [diff.sha256(path) for path in binaries]
    scratch = ROOT / ".tmp"
    scratch.mkdir(exist_ok=True)
    totals = {"cases": 0, "comparisons": 0, "executedTightenedDestinations": 0,
              "typedFaultControls": 0, "syntacticJumps": 0, "permittedOrigins": 0,
              "removedOrigins": 0, "affectedLabels": 0}
    family_counts = {}
    with tempfile.TemporaryDirectory(prefix="incoming-tightening-", dir=scratch) as directory:
        directory = Path(directory)
        candidates = cases(options.fixtures, directory, options.variants)
        unique_cases, skipped_duplicates = deduplicate_cases(candidates)
        for family, variant_name, source in unique_cases:
            result = run_case(binary, family, source, flags, directory / "input.json", tuple(digests[:2]))
            totals["cases"] += 1
            family_counts[family] = family_counts.get(family, 0) + 1
            for key in ("comparisons", "executedTightenedDestinations", "typedFaultControls"):
                totals[key] += result[key]
            for key in ("syntacticJumps", "permittedOrigins", "removedOrigins", "affectedLabels"):
                totals[key] += result["annotationStats"][key]
            print(json.dumps({"case": source.name, "family": family, "variant": variant_name,
                              "status": "passed", **result}, sort_keys=True), flush=True)
    if digests != [diff.sha256(path) for path in binaries]:
        raise ValueError("campaign executables changed during testing")
    if totals["executedTightenedDestinations"] == 0 or totals["removedOrigins"] == 0:
        raise ValueError("campaign provided no executed tightening evidence")
    print(json.dumps({"tightening-campaign": "passed", "families": family_counts, **totals,
                      "candidateInputs": len(candidates), "uniqueSourceInputs": len(unique_cases),
                      "skippedDuplicateInputs": skipped_duplicates,
                      "coverage": "bounded structural variants; first executed tightened target per tape",
                      "totalDynamicJumpCount": "not measured"}, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (diff.Incomplete, diff.Mismatch, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
