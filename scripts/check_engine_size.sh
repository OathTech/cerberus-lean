#!/bin/bash
# check_engine_size.sh — arc-18 C1 (2026-08-25): THE ENGINE-SIZE WATCH
# (the down-pressure register's ENGINE row; contracts doc
# lean_frontend/docs/2026-08-25_reasoning-layer-contracts.md §3b,
# register row R3).
#
# The evaluator is contractually a THIN LAW-APPLIER: any mechanism
# encoding semantic knowledge that fires twice becomes a registered
# law (the engine-to-law rule), and the engine's line count is a
# WATCHED METRIC under down-pressure like proof length. This script
# reports per-module line counts for the engine surface and compares
# them to the recorded baseline (scripts/engine_size_baseline.txt).
#
# Semantics (charter-mandated WARN level, deliberately NOT fail):
#   * per-module counts print verbatim (the record quotes them);
#   * growth beyond the baseline prints a loud WARNING naming the
#     module (the audit reads warnings; un-annotated growth at review
#     is an engine-to-law finding — the register row, not this script,
#     carries the enforcement);
#   * shrinkage prints as such (down-pressure working) — re-baseline
#     deliberately, same commit, with the reason in the baseline
#     header;
#   * exit is 0 on any size movement. Exit 1 ONLY for a broken
#     instrument (missing baseline, missing module) — fail-noisy on
#     structural breakage, warn-only on the watched metric.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELSEM="$SCRIPT_DIR/../lean_frontend/relsem/RelSem"
BASELINE="$SCRIPT_DIR/engine_size_baseline.txt"

# The engine surface: the decomposed round evaluator + the emitter +
# the ground discharger (meta code only; law modules are NOT engine).
MODULES=(
    "RoundEval.lean"
    "RoundEval/Core.lean"
    "RoundEval/Hyp.lean"
    "RoundEval/Mint.lean"
    "RoundEval/Classify.lean"
    "RoundEval/Arith.lean"
    "RoundEval/Lanes.lean"
    "RoundEval/Rounds.lean"
    "RoundEval/Assembly.lean"
    "DeriveState.lean"
    "WpGround.lean"
    "LawRegistry.lean"
    "SegmentFaces.lean"
)

if [[ ! -f "$BASELINE" ]]; then
    echo "check_engine_size: FAIL — baseline $BASELINE missing (the watch needs its record)"
    exit 1
fi

fail=0
total=0
warned=0
for m in "${MODULES[@]}"; do
    path="$RELSEM/$m"
    if [[ ! -f "$path" ]]; then
        echo "check_engine_size: FAIL — engine module $m missing (decomposition drift: update MODULES + baseline deliberately)"
        fail=1
        continue
    fi
    lines=$(wc -l < "$path" | tr -d ' ')
    total=$((total + lines))
    base=$(awk -v m="$m" '$1 == m { print $2 }' "$BASELINE")
    if [[ -z "$base" ]]; then
        echo "check_engine_size: WARNING — $m ($lines lines) has no baseline row (new engine module: justify + baseline it)"
        warned=1
    elif (( lines > base )); then
        echo "check_engine_size: WARNING — $m grew $base -> $lines lines (engine-to-law rule: semantic mechanism firing twice becomes a registered law; annotate or shrink)"
        warned=1
    elif (( lines < base )); then
        echo "check_engine_size: $m shrank $base -> $lines lines (down-pressure working; re-baseline with reason)"
    else
        echo "check_engine_size: $m at baseline ($lines lines)"
    fi
done

base_total=$(awk '$1 == "TOTAL" { print $2 }' "$BASELINE")
echo "check_engine_size: engine total $total lines (baseline ${base_total:-unrecorded})"
if [[ -n "${base_total:-}" ]] && (( total > base_total )); then
    echo "check_engine_size: WARNING — engine total grew ${base_total} -> ${total}"
    warned=1
fi

if (( fail )); then exit 1; fi
if (( warned )); then
    echo "check_engine_size: WARN (watched metric moved — see warnings above; not a gate failure)"
fi
echo "check_engine_size: OK (reporting instrument; enforcement lives in the R3 register row)"
exit 0
