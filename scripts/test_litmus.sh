#!/bin/bash
# Exhaustive SC differential: compare full observations, then the independently
# stated reference projection. No result is inferred from agreement alone.
# Donor: arc/validation-foundations-concurrency at 86a2aea54; adapted to the
# 2026-09-21 SC prototype charter. See tests/litmus/README.md for exact domains.
set -uo pipefail

# Hermetic plants run without building or requiring a working SC executor.
if [[ "${1:-}" == --selftest ]]; then
    python3 "$(dirname "${BASH_SOURCE[0]}")/test_litmus_observations.py" &&
        python3 "$(dirname "${BASH_SOURCE[0]}")/test_litmus_references.py"
    exit $?
fi
case "${1:-}" in
    --check) MODE=check ;;
    --plant) MODE=plant ;;
    *) echo "usage: $0 --check | --selftest | --plant" >&2; exit 2 ;;
esac
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
TIMEOUT_SECS="${TIMEOUT_SECS:-60}"
command -v timeout &>/dev/null || { echo "Error: timeout not found" >&2; exit 1; }
LITMUS_DIR="${LITMUS_DIR:-$PROJECT_ROOT/tests/litmus}"
EXPECTATIONS="$LITMUS_DIR/expectations.txt"
MODEL_FLAGS=(--concurrency=sc)
[[ -d "$LITMUS_DIR" && -f "$EXPECTATIONS" ]] || { echo "Error: missing litmus corpus or expectations" >&2; exit 1; }
if [[ "${SKIP_BUILD:-0}" != 1 ]]; then
    build_cerberus || exit 1
    build_lean || exit 1
fi
require_time_bin
OUTPUT_DIR="$OBSERVATION_RUN_DIR"
mkdir -p "$OUTPUT_DIR" || exit 1
echo "Raw observation evidence: $OUTPUT_DIR"
cd "$PROJECT_ROOT" || exit 1
if ! python3 "$LITMUS_DIR/sc_reference.py" --check "$EXPECTATIONS" > "$OUTPUT_DIR/derivation.log" 2>&1; then
    cat "$OUTPUT_DIR/derivation.log"
    echo "LITMUS LANE FAILED (reference derivation)"; exit 1
fi
tail -1 "$OUTPUT_DIR/derivation.log"

# ---- helpers ----------------------------------------------------------------
# tokens_of <output-file> -> prints the rendered set on stdout, the ERROR
# msgs (if any) to the file <output-file>.errmsgs; rc 1 if nothing parsable.
tokens_of() {
    local f="$1" rc="$2" toks
    toks=$(python3 "$OBSERVATION_CODEC" reference-set --capture "$f" --status "$rc" --policy litmus) || return 1
    python3 "$OBSERVATION_CODEC" messages --capture "$f" --policy litmus > "$f.errmsgs" || return 1
    printf '%s\n' "$toks"
}

run_oracle() {   # <file.c> <out> [model-flag...]
    local src="$1" out="$2"; shift 2
    observation_capture "$out" "$TIME_BIN" -v -o "$out.time" timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" \
        --runtime="$PROJECT_ROOT/_build/install/default" \
        --nolibc --exec --batch --mode=exhaustive "$@" "$src" > "$out"
}
run_lean() {     # <file.c> <json> <out> [model-flag...]
    local src="$1" json="$2" out="$3" rc=0; shift 3
    observation_capture "$out.bridge" timeout "${TIMEOUT_SECS}s" "$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default" \
        --cabs-json "$src" > "$json.display" || rc=$?
    if [[ $rc -ne 0 ]]; then
        printf 'Cabs producer failed (exit %s); Lean not run\n' "$rc" > "$out.capture-error"
        return "$rc"
    fi
    if [[ ! -s "$out.bridge.stdout" ]]; then
        printf '%s\n' 'Cabs producer emitted no input; Lean not run' > "$out.capture-error"
        return 1
    fi
    if ! cp "$out.bridge.stdout" "$json"; then
        printf '%s\n' 'Could not stage Cabs input; Lean not run' > "$out.capture-error"
        return 1
    fi
    observation_capture "$out" "${CAPPED_TEST[@]}" "$TIME_BIN" -v -o "$out.time" timeout "${TIMEOUT_SECS}s" \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch "$json" "$@" > "$out"
}

# read_rows <file> -> fills ROW_CLASS[name] ROW_TARGET[name]
declare -A ROW_CLASS ROW_TARGET
read_rows() {
    ROW_CLASS=(); ROW_TARGET=()
    local name cls target rest line=0
    while read -r name cls target rest || [[ -n "$name$cls$target$rest" ]]; do
        line=$((line+1))
        [[ -z "$name" || "$name" == \#* ]] && continue
        [[ -z "$cls" || -z "$target" || -n "$rest" ]] && { echo "Error: malformed row in $1: '$name $cls $target $rest'" >&2; exit 1; }
        [[ -z "${ROW_CLASS[$name]+x}" ]] || { echo "Error: duplicate row '$name' at $1:$line" >&2; exit 1; }
        [[ "$name" != */* && "$name" == *.c ]] || { echo "Error: invalid file name at $1:$line" >&2; exit 1; }
        [[ "$cls" =~ ^(SC|RMW|NONSC|PENDING)$ ]] || { echo "Error: unknown class at $1:$line" >&2; exit 1; }
        ROW_CLASS["$name"]="$cls"; ROW_TARGET["$name"]="$target"
    done < "$1"
}

# run_all -> fills SET[name], ERRMSG_O[name], ERRMSG_L[name]; DIFF_FAIL count
declare -A SET ERRMSG_O ERRMSG_L
DIFF_FAIL=0
run_all() {
    local src name oset lset orc lrc n_files=0
    SET=(); ERRMSG_O=(); ERRMSG_L=(); DIFF_FAIL=0
    for src in "$LITMUS_DIR"/*.c; do
        [[ -f "$src" ]] || continue
        name=$(basename "$src"); n_files=$((n_files+1))
        orc=0; lrc=0
        run_oracle "$src" "$OUTPUT_DIR/$name.oracle" "${MODEL_FLAGS[@]}" || orc=$?
        oset=$(tokens_of "$OUTPUT_DIR/$name.oracle" "$orc") || {
            echo "[FAIL] $name: invalid/incomplete oracle observation (exit $orc)"; DIFF_FAIL=$((DIFF_FAIL+1)); continue; }
        run_lean "$src" "$OUTPUT_DIR/$name.json" "$OUTPUT_DIR/$name.lean" "${MODEL_FLAGS[@]}" || lrc=$?
        lset=$(tokens_of "$OUTPUT_DIR/$name.lean" "$lrc") || {
            echo "[FAIL] $name: invalid/incomplete Lean observation (exit $lrc)"; DIFF_FAIL=$((DIFF_FAIL+1)); continue; }
        ERRMSG_O["$name"]=$(head -1 "$OUTPUT_DIR/$name.oracle.errmsgs" 2>/dev/null)
        ERRMSG_L["$name"]=$(head -1 "$OUTPUT_DIR/$name.lean.errmsgs" 2>/dev/null)
        if ! observation_compare "$OUTPUT_DIR/$name.oracle" "$OUTPUT_DIR/$name.lean" --policy litmus --comparison set; then
            echo "[DIFF] $name: complete observations differ (reference projections: oracle $oset, Lean $lset)"; DIFF_FAIL=$((DIFF_FAIL+1)); continue
        fi
        if [[ "$oset" != "$lset" ]]; then
            echo "[DIFF] $name: oracle $oset vs Lean $lset"; DIFF_FAIL=$((DIFF_FAIL+1)); continue
        fi
        SET["$name"]="$oset"
    done
    if [[ $n_files -eq 0 ]]; then
        echo "[FAIL] zero programs under $LITMUS_DIR"; DIFF_FAIL=$((DIFF_FAIL+1))
    fi
}

# compare_to <rows-file> <label> -> prints per-row verdicts; returns fail count via COMPARE_FAIL
COMPARE_FAIL=0; declare -A CLASS_RED
compare_to() {
    read_rows "$1"
    local src name target cls n_files=0
    COMPARE_FAIL=0; CLASS_RED=()
    for src in "$LITMUS_DIR"/*.c; do
        [[ -f "$src" ]] || continue
        name=$(basename "$src"); n_files=$((n_files+1))
        if [[ -z "${ROW_CLASS[$name]:-}" ]]; then
            echo "[FAIL] $name: no row in $(basename "$1") (bijection)"; COMPARE_FAIL=$((COMPARE_FAIL+1)); continue
        fi
        [[ -n "${SET[$name]:-}" ]] || { COMPARE_FAIL=$((COMPARE_FAIL+1)); continue; }   # already reported by run_all
        target="${ROW_TARGET[$name]}"; cls="${ROW_CLASS[$name]}"
        if [[ "$cls" == PENDING ]]; then
            echo "[PENDING] $name: reference classification unresolved; no support credit"
            COMPARE_FAIL=$((COMPARE_FAIL+1)); CLASS_RED["$cls"]=1
        elif [[ "$target" == "REFUSE" ]]; then
            if python3 "$OBSERVATION_CODEC" refusal --capture "$OUTPUT_DIR/$name.oracle" > "$OUTPUT_DIR/$name.oracle.refusal" &&
                    python3 "$OBSERVATION_CODEC" refusal --capture "$OUTPUT_DIR/$name.lean" > "$OUTPUT_DIR/$name.lean.refusal"; then
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
echo "litmus lane (SC prototype 2026-09-21) — mode: $MODE"
run_all
if [[ "$MODE" == check ]]; then
    compare_to "$EXPECTATIONS" target
    echo "SUMMARY: programs=${#SET[@]} engine_failures=$DIFF_FAIL reference_failures=$COMPARE_FAIL"
    if [[ $DIFF_FAIL -gt 0 || $COMPARE_FAIL -gt 0 ]]; then echo "LITMUS LANE FAILED"; exit 1; fi
    echo "ALL ROWS AT target"; exit 0
fi
# Connection plants require an already green lane. They never rewrite targets.
compare_to "$EXPECTATIONS" target > "$OUTPUT_DIR/plant.control.log"
if [[ $DIFF_FAIL -gt 0 || $COMPARE_FAIL -gt 0 ]]; then
    echo "PLANT ABORTED: positive control failed; see plant.control.log"; exit 1
fi
python3 "$SCRIPT_DIR/test_litmus_observations.py" || exit 1
python3 "$SCRIPT_DIR/test_litmus_references.py" || exit 1
echo "*** PLANT MODE: deliberately corrupting a reference and emptying the corpus ***"
awk 'BEGIN {changed=0} !changed && NF && $1 !~ /^#/ {$3="{Specified(424242)}"; changed=1} {print}' "$EXPECTATIONS" > "$OUTPUT_DIR/plant.rows"
compare_to "$OUTPUT_DIR/plant.rows" PLANT > "$OUTPUT_DIR/plant.row.log"; row_fail=$COMPARE_FAIL
mkdir -p "$OUTPUT_DIR/empty"
LITMUS_DIR="$OUTPUT_DIR/empty"
run_all > "$OUTPUT_DIR/plant.empty.log"; empty_run_fail=$DIFF_FAIL
compare_to "$EXPECTATIONS" PLANT >> "$OUTPUT_DIR/plant.empty.log"; empty_compare_fail=$COMPARE_FAIL
if [[ $row_fail -gt 0 && $empty_run_fail -gt 0 && $empty_compare_fail -gt 0 ]]; then
    echo "PLANTS TRIPPED"; exit 0
fi
echo "PLANT FAILED TO TRIP"; exit 1
