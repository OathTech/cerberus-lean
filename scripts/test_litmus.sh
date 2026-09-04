#!/bin/bash
# test_litmus.sh — the concurrency litmus lane (charter
# lean_frontend/docs/2026-09-04_concurrency-phase0-sc-charter.md, slice S0;
# exit criterion E1). Programs: tests/litmus/*.c (parallel composition
# `{-{ ... ||| ... }-}`, C11 atomics). Both engines run every program in
# EXHAUSTIVE mode and the lane compares OUTCOME SETS:
#
#   oracle set  = tokens of `cerberus --nolibc --exec --batch --mode=exhaustive`
#   Lean set    = tokens of `cerberus --cabs-json` -> `cerberus-lean --batch`
#   token       = X for `Defined {value: "X", ...}`  (e.g. Specified(3))
#               | U for `Undefined {ub: "U", ...}`   (e.g. UB005_data_race)
#               | ERROR for `Error {msg: ...}`        (the msg is kept aside)
#               | INTERNAL_ERROR(M) for an uncaught failure with message M:
#                 oracle `internal error: M` / Lean `PANIC at ... failwithIImpl
#                 ...: M` (the failwithI mirror) — the message is part of the
#                 token (spaces rendered `_`), so a mismatched failure text is a DIFF
#   set         = sorted, de-duplicated tokens, rendered `{a,b,...}`
#
# Three-way agreement is required, fail-closed, per row:
#   (1) oracle set == Lean set            (the zero-discrepancy rule);
#   (2) that set == the row's reference:
#         --check          tests/litmus/expectations.txt (the Phase-0 TARGET:
#                          RED BY DESIGN until slices S2/S3/S4 land — the
#                          summary says which classes are red);
#         --check-before   tests/litmus/before_baseline.txt (the measured
#                          "before" pin: green on the pre-S2 tree; every
#                          later movement is re-recorded deliberately with
#                          --record-before in the slice that causes it);
#   (3) every tests/litmus/*.c has a row and every row has a file
#       (bijection; an orphan on either side is fatal);
#   (4) sc_reference.py --check expectations.txt passes (the SC rows equal
#       their mechanical derivation) — run first, always.
# A REFUSE target is met iff both engines emit exactly one ERROR token whose
# msg matches REFUSE_RE (pinned precisely in slice S1 when the typed refusal
# exists; until then the RE below is the placeholder and NONSC rows are red).
#
#   --record-before   rewrite before_baseline.txt from the two engines (only
#                     rows where they AGREE are written; a disagreement is
#                     fatal and nothing is written)
#   --plant           vacuity plants: (a) an in-memory corruption of one
#                     baseline row must make --check-before FAIL; (b) an
#                     empty corpus must FAIL. Loud PLANT banner. rc 0 iff
#                     both plants trip.
#
# Serial by construction (one program at a time, both engines); the Lean
# side runs under the per-test cgroup cap (CAPPED_TEST, common.sh). Any
# cap kill / timeout / unparsable output is a lane FAILURE, never a skip.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-60}"
command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }
LITMUS_DIR="${LITMUS_DIR:-$PROJECT_ROOT/tests/litmus}"
EXPECTATIONS="$LITMUS_DIR/expectations.txt"
BASELINE="$LITMUS_DIR/before_baseline.txt"
REFUSE_RE="${REFUSE_RE:-[Cc]oncurrency}"   # placeholder until S1 pins the typed refusal text

MODE=""
case "${1:-}" in
    --check) MODE=check ;;
    --check-before) MODE=before ;;
    --record-before) MODE=record ;;
    --plant) MODE=plant ;;
    *) echo "usage: $0 --check | --check-before | --record-before | --plant" >&2; exit 2 ;;
esac

[[ -d "$LITMUS_DIR" ]] || { echo "Error: $LITMUS_DIR not found" >&2; exit 1; }
[[ -f "$EXPECTATIONS" ]] || { echo "Error: $EXPECTATIONS missing (fail-closed)" >&2; exit 1; }

build_cerberus
build_lean
require_time_bin

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/litmus.XXXXXXXXXX") || { echo "mktemp failed" >&2; exit 1; }
register_cleanup "$OUTPUT_DIR"
cd "$PROJECT_ROOT" || exit 1

# ---- (4) the derivation gate --------------------------------------------
if ! python3 "$LITMUS_DIR/sc_reference.py" --check "$EXPECTATIONS" > "$OUTPUT_DIR/derivation.log" 2>&1; then
    cat "$OUTPUT_DIR/derivation.log"
    echo "LITMUS LANE FAILED (expectations.txt disagrees with sc_reference.py)"
    exit 1
fi
tail -1 "$OUTPUT_DIR/derivation.log"

# ---- helpers ----------------------------------------------------------------
# tokens_of <output-file> -> prints the rendered set on stdout, the ERROR
# msgs (if any) to the file <output-file>.errmsgs; rc 1 if nothing parsable.
tokens_of() {
    local f="$1" toks
    toks=$(sed -n \
        -e 's/^Defined {value: "\([^"]*\)".*$/\1/p' \
        -e 's/^Undefined {ub: "\([^"]*\)".*$/\1/p' \
        -e 's/^Error {msg: .*$/ERROR/p' \
        -e 's/^internal error: \(.*\)$/INTERNAL_ERROR(\1)/p' \
        -e 's/^PANIC at .*failwithIImpl [^:]*:[0-9]*:[0-9]*: \(.*\)$/INTERNAL_ERROR(\1)/p' "$f" \
        | sed '/^INTERNAL_ERROR(/ s/ /_/g' | LC_ALL=C sort -u)   # tokens are whitespace-free (row format)
    sed -n 's/^Error {msg: "\(.*\)"}.*$/\1/p' "$f" > "$f.errmsgs"
    [[ -n "$toks" ]] || return 1
    printf '{%s}\n' "$(printf '%s\n' "$toks" | paste -sd, -)"
}

run_oracle() {   # <file.c> <out>
    "$TIME_BIN" -v -o "$2.time" timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" \
        --runtime="$PROJECT_ROOT/_build/install/default" \
        --nolibc --exec --batch --mode=exhaustive "$1" > "$2" 2>&1
}
run_lean() {     # <file.c> <json> <out>
    timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" \
        --cabs-json "$1" > "$2" 2> "$2.err" || return 1
    [[ -s "$2" ]] || return 1
    "${CAPPED_TEST[@]}" "$TIME_BIN" -v -o "$3.time" timeout "${TIMEOUT_SECS}s" \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch "$2" 2>&1 \
        | grep -v '^cerberus-lean-proj env:' > "$3"
    return "${PIPESTATUS[0]}"
}

# read_rows <file> -> fills ROW_CLASS[name] ROW_TARGET[name]
declare -A ROW_CLASS ROW_TARGET
read_rows() {
    ROW_CLASS=(); ROW_TARGET=()
    local name cls target rest
    while read -r name cls target rest; do
        [[ -z "$name" || "$name" == \#* ]] && continue
        [[ -z "$cls" || -z "$target" || -n "$rest" ]] && { echo "Error: malformed row in $1: '$name $cls $target $rest'" >&2; exit 1; }
        ROW_CLASS["$name"]="$cls"; ROW_TARGET["$name"]="$target"
    done < "$1"
}

# run_all -> fills SET[name], ERRMSG_O[name], ERRMSG_L[name]; DIFF_FAIL count
declare -A SET ERRMSG_O ERRMSG_L
DIFF_FAIL=0
run_all() {
    local src name oset lset
    for src in "$LITMUS_DIR"/*.c; do
        name=$(basename "$src")
        run_oracle "$src" "$OUTPUT_DIR/$name.oracle"
        oset=$(tokens_of "$OUTPUT_DIR/$name.oracle") || {
            echo "[FAIL] $name: oracle output unparsable: $(head -1 "$OUTPUT_DIR/$name.oracle")"; DIFF_FAIL=$((DIFF_FAIL+1)); continue; }
        if ! run_lean "$src" "$OUTPUT_DIR/$name.json" "$OUTPUT_DIR/$name.lean"; then
            lrc=$?
            if is_cap_kill "$lrc" "$OUTPUT_DIR/$name.lean"; then
                echo "[FAIL] $name: Lean $(kill_label "$lrc" "$OUTPUT_DIR/$name.lean")"; DIFF_FAIL=$((DIFF_FAIL+1)); continue
            fi
            # nonzero rc is the runM convention for Undefined/Error lines: parse anyway
        fi
        lset=$(tokens_of "$OUTPUT_DIR/$name.lean") || {
            echo "[FAIL] $name: Lean output unparsable: $(head -1 "$OUTPUT_DIR/$name.lean" 2>/dev/null)"; DIFF_FAIL=$((DIFF_FAIL+1)); continue; }
        ERRMSG_O["$name"]=$(head -1 "$OUTPUT_DIR/$name.oracle.errmsgs" 2>/dev/null)
        ERRMSG_L["$name"]=$(head -1 "$OUTPUT_DIR/$name.lean.errmsgs" 2>/dev/null)
        if [[ "$oset" != "$lset" ]]; then
            echo "[DIFF] $name: oracle $oset vs Lean $lset"; DIFF_FAIL=$((DIFF_FAIL+1)); continue
        fi
        SET["$name"]="$oset"
    done
}

# compare_to <rows-file> <label> -> prints per-row verdicts; returns fail count via COMPARE_FAIL
COMPARE_FAIL=0; declare -A CLASS_RED
compare_to() {
    read_rows "$1"
    local name target cls n_files=0
    COMPARE_FAIL=0; CLASS_RED=()
    for src in "$LITMUS_DIR"/*.c; do
        name=$(basename "$src"); n_files=$((n_files+1))
        if [[ -z "${ROW_CLASS[$name]:-}" ]]; then
            echo "[FAIL] $name: no row in $(basename "$1") (bijection)"; COMPARE_FAIL=$((COMPARE_FAIL+1)); continue
        fi
        [[ -n "${SET[$name]:-}" ]] || { COMPARE_FAIL=$((COMPARE_FAIL+1)); continue; }   # already reported by run_all
        target="${ROW_TARGET[$name]}"; cls="${ROW_CLASS[$name]}"
        if [[ "$target" == "REFUSE" ]]; then
            if [[ "${SET[$name]}" == "{ERROR}" && "${ERRMSG_O[$name]}" =~ $REFUSE_RE && "${ERRMSG_L[$name]}" =~ $REFUSE_RE ]]; then
                echo "[MATCH] $name ($cls): REFUSE (\"${ERRMSG_O[$name]}\")"
            else
                echo "[MISMATCH] $name ($cls): $2 REFUSE vs engines ${SET[$name]}${ERRMSG_O[$name]:+ (\"${ERRMSG_O[$name]}\")}"
                COMPARE_FAIL=$((COMPARE_FAIL+1)); CLASS_RED["$cls"]=1
            fi
        elif [[ "${SET[$name]}" == "$target" ]]; then
            echo "[MATCH] $name ($cls): ${SET[$name]}"
        else
            echo "[MISMATCH] $name ($cls): $2 $target vs engines ${SET[$name]}${ERRMSG_O[$name]:+ (\"${ERRMSG_O[$name]}\")}"
            COMPARE_FAIL=$((COMPARE_FAIL+1)); CLASS_RED["$cls"]=1
        fi
    done
    for name in "${!ROW_CLASS[@]}"; do
        [[ -f "$LITMUS_DIR/$name" ]] || { echo "[FAIL] row $name in $(basename "$1") has no file (bijection)"; COMPARE_FAIL=$((COMPARE_FAIL+1)); }
    done
    if [[ $n_files -eq 0 ]]; then echo "[FAIL] zero programs under $LITMUS_DIR (vacuous pass refused)"; COMPARE_FAIL=$((COMPARE_FAIL+1)); fi
}

echo ""
echo "litmus lane (concurrency Phase 0, charter 2026-09-04) — mode: $MODE"
echo "======================================================================"

case "$MODE" in
  record)
    run_all
    if [[ $DIFF_FAIL -gt 0 ]]; then echo "LITMUS LANE FAILED (engines disagree or unparsable: $DIFF_FAIL; baseline NOT written)"; exit 1; fi
    read_rows "$EXPECTATIONS"
    {
      echo "# tests/litmus/before_baseline.txt — MEASURED outcome sets, both engines in"
      echo "# agreement, recorded by scripts/test_litmus.sh --record-before on $(date -u +%Y-%m-%d)."
      echo "# This is the regression PIN (--check-before), not the target (that is"
      echo "# expectations.txt). Re-recorded deliberately by the slice that moves it;"
      echo "# the movement is described in that slice's record. Row: <file> <class> <set>"
      echo "# [<first Error msg, if any>]"
      for src in "$LITMUS_DIR"/*.c; do
        name=$(basename "$src")
        printf '%s  %s  %s%s\n' "$name" "${ROW_CLASS[$name]:-UNCLASSIFIED}" "${SET[$name]}" "${ERRMSG_O[$name]:+  [$(printf '%s' "${ERRMSG_O[$name]}" | tr -d '\n')]}"
      done
    } > "$BASELINE"
    echo "recorded $(grep -vc '^#' "$BASELINE") rows to $BASELINE"; exit 0 ;;
  before|check)
    if [[ "$MODE" == before ]]; then ref="$BASELINE"; label="baseline"; [[ -f "$BASELINE" ]] || { echo "Error: $BASELINE missing — run --record-before first (fail-closed)" >&2; exit 1; }
    else ref="$EXPECTATIONS"; label="target"; fi
    run_all
    # baseline rows carry an optional trailing [msg] column: strip it for read_rows
    if [[ "$MODE" == before ]]; then sed 's/  \[.*\]$//' "$BASELINE" > "$OUTPUT_DIR/baseline.rows"; ref="$OUTPUT_DIR/baseline.rows"; fi
    compare_to "$ref" "$label"
    total=$(ls "$LITMUS_DIR"/*.c 2>/dev/null | wc -l)
    echo ""
    red="${!CLASS_RED[*]}"; [[ -n "$red" ]] || red=none
    echo "SUMMARY: mode=$MODE programs=$total engine_disagreements=$DIFF_FAIL ${label}_mismatches=$((COMPARE_FAIL - DIFF_FAIL)) red_classes=$red"
    if [[ $DIFF_FAIL -gt 0 || $COMPARE_FAIL -gt 0 ]]; then echo "LITMUS LANE FAILED"; exit 1; fi
    echo "ALL ROWS AT $label"; exit 0 ;;
  plant)
    echo "*** PLANT MODE: the verdicts below are DELIBERATELY corrupted; a green plant means the lane is vacuous ***"
    [[ -f "$BASELINE" ]] || { echo "Error: $BASELINE missing — run --record-before first" >&2; exit 1; }
    run_all
    if [[ $DIFF_FAIL -gt 0 ]]; then echo "PLANT ABORTED: engines disagree ($DIFF_FAIL) — fix the lane state first"; exit 1; fi
    # (a) corrupt the first baseline row's set
    sed 's/  \[.*\]$//' "$BASELINE" > "$OUTPUT_DIR/plant.rows"
    first=$(grep -v '^#' "$OUTPUT_DIR/plant.rows" | head -1 | awk '{print $1}')
    awk -v n="$first" '$1==n {$3="{Specified(424242)}"} {print}' "$OUTPUT_DIR/plant.rows" > "$OUTPUT_DIR/plant.rows.a"
    compare_to "$OUTPUT_DIR/plant.rows.a" "PLANT" > "$OUTPUT_DIR/plant.a.log"; a_fail=$COMPARE_FAIL
    # (b) empty corpus
    mkdir -p "$OUTPUT_DIR/empty"; saved="$LITMUS_DIR"; LITMUS_DIR="$OUTPUT_DIR/empty"
    compare_to "$OUTPUT_DIR/plant.rows" "PLANT" > "$OUTPUT_DIR/plant.b.log"; b_fail=$COMPARE_FAIL; LITMUS_DIR="$saved"
    echo "plant (a) corrupted row '$first': mismatches=$a_fail (want >=1)"
    echo "plant (b) empty corpus: failures=$b_fail (want >=1)"
    if [[ $a_fail -ge 1 && $b_fail -ge 1 ]]; then echo "PLANTS TRIPPED (lane is not vacuous)"; exit 0; fi
    echo "PLANT FAILED TO TRIP — THE LANE IS VACUOUS"; exit 1 ;;
esac
