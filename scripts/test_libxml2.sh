#!/bin/bash
# test_libxml2.sh — arc-5 S3 exit-criterion differential (charter success
# condition 3): libxml2's chvalid.c + the generated boundary battery, linked
# as two TUs through BOTH pipelines, must agree 100%.
#
# The battery (1354 boundary code points x 22 observations each; see
# tests/libxml2/gen_chvalid_battery.py) is committed as SLICE programs under
# tests/libxml2/battery/ — both interpreters retain dead allocations, so exec
# cost is quadratic in program length and one whole-battery program exceeds
# the 300 s per-invocation resource cap on both sides (measured; generator
# docstring has the numbers). Each slice is run as its own 2-TU link:
#
#   OCaml : cerberus --nolibc --exec --batch  <slice>.c chvalid.c
#           (default --mode=random: ONE trace — smt2.ml:23-31 picks branches
#           with OCaml's PRNG, which is TIME-SEEDED PER RUN [corrected per
#           arc-5 audits]: util/cerb_any.ml:1 self_inits at module load
#           (Cerb_any.bounded_integer linked in via generated
#           core_run.ml:1099) and driver_ocaml.ml:153/190 self_init again
#           in batch_drive/drive — NOT deterministic across runs.
#           Exhaustive mode is combinatorially infeasible at this program
#           size: measured 175 executions for a 2-call program.)
#   Lean  : cerberus-lean --batch --first  <slice>.json chvalid.json
#           (single-trace runner CerbND.runND1; the trace-selection
#           divergence vs OCaml's PRNG is recorded there. --first returns
#           branch-index-0's trace, which equals the LAST execution of the
#           exhaustive list — exhaustive mirrors OCaml's prepend order —
#           NOT exhaustive's execution 0. Sound here because the battery is
#           pure: its verdict is trace-independent — empirically all 175
#           exhaustive executions of the probe program agreed. A
#           trace-sensitive battery would FLAKE (the OCaml side's trace
#           varies run to run), not deterministically fail, and is
#           therefore FORBIDDEN in this gate absent a seed-pinning story.)
#
# Comparison is the multi_tu form (test_multi_tu.sh), tightened per slice:
# the single batch verdict LINE must be byte-identical (checksum value +
# stdout + stderr + blocked), exit codes must be consistent, and the OCaml
# oracle output must equal the committed baseline
# (tests/libxml2/chvalid_baseline.txt) — oracle drift is a failure, not a
# silent re-baseline.
#
# Fail-closed: pin drift (libxml2_prep.sh --check), battery drift (committed
# slices != regenerated), missing baseline entry, any crash/timeout/mismatch
# => exit 1.
#
# Resource bounds (operator directive, arc-5): every cerberus invocation on
# libxml2-sized inputs runs under the per-test cgroup cap (`scripts/capped`,
# CERB_TEST_MEM_MAX default 4G RSS — mem-scale S2, 2026-09-02, Q2 [USER
# 2026-09-02], replacing the arc-5 `ulimit -v 4000000`; a cap kill is exit
# 137 + capped's KILLED banner, reported as FAIL … KILLED) + timeout; per-slice
# wall/maxRSS are reported.
#
# Usage: ./scripts/test_libxml2.sh [--record-baseline] [slice-name ...]
#   --record-baseline  rewrite tests/libxml2/chvalid_baseline.txt from the
#                      OCaml oracle (instrument change: commit only with
#                      justification). Requires running ALL slices.
#   slice-name ...     run only these slices (e.g. chvalid_battery_07) —
#                      debugging aid; baseline is still checked per slice.
#
# Environment:
#   TIMEOUT_SECS  per-invocation timeout (default: 300)
#   LIBXML2_DIR   libxml2 source override (see libxml2_prep.sh)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-300}"

RECORD_BASELINE=false
declare -a ONLY=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --record-baseline) RECORD_BASELINE=true; shift ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) ONLY+=("$1"); shift ;;
    esac
done
if $RECORD_BASELINE && [[ ${#ONLY[@]} -gt 0 ]]; then
    echo "Error: --record-baseline requires running ALL slices" >&2; exit 1
fi

command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }

BASELINE="$PROJECT_ROOT/tests/libxml2/chvalid_baseline.txt"
BATTERY_DIR="$PROJECT_ROOT/tests/libxml2/battery"
GENERATOR="$PROJECT_ROOT/tests/libxml2/gen_chvalid_battery.py"

fail() { echo "FAIL: $*" >&2; exit 1; }

build_cerberus
build_lean

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR (run dune install cerberus-lib)"
[[ -d "$BATTERY_DIR" ]] || fail "battery dir not found: $BATTERY_DIR"
$RECORD_BASELINE || [[ -f "$BASELINE" ]] || fail "baseline not found: $BASELINE (run --record-baseline once, commit with justification)"

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/libxml2-test.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"

# Lean binary locates runtime/libcore relative to cwd
cd "$PROJECT_ROOT" || fail "cannot cd to $PROJECT_ROOT"

echo ""
echo "libxml2 chvalid differential (arc-5 S3 exit criterion)"
echo "=================================================="

# --- 1. pins + prep args (fail-closed inside libxml2_prep.sh) ---------------
# NOTE: not `mapfile -t X < <(cmd) || fail` — mapfile succeeds even when
# the process-substituted cmd fails, so that guard is dead (arc-6 S5f
# audit fix; S2-arc-5 pattern: capture rc explicitly, then split).
prep_out=$("$PROJECT_ROOT/scripts/libxml2_prep.sh" chvalid.c) \
    || fail "libxml2_prep.sh failed (pin drift or missing source)"
[[ -n "$prep_out" ]] || fail "libxml2_prep.sh emitted no args"
mapfile -t PREP <<< "$prep_out"
[[ ${#PREP[@]} -ge 2 ]] || fail "libxml2_prep.sh emitted no args"
CHVALID_TU="${PREP[${#PREP[@]}-1]}"
FLAGS=("${PREP[@]:0:${#PREP[@]}-1}")
echo "[prep] pins verified; chvalid TU: $CHVALID_TU"

# --- 2. battery drift check (committed slices == regenerated) ---------------
LIBXML2_ROOT="$(dirname "$CHVALID_TU")"
python3 "$GENERATOR" "$LIBXML2_ROOT/codegen/ranges.inc" --out-dir "$OUTPUT_DIR/battery_regen" \
    2> "$OUTPUT_DIR/gen.log" || fail "battery generator failed: $(cat "$OUTPUT_DIR/gen.log")"
diff -r "$OUTPUT_DIR/battery_regen" "$BATTERY_DIR" > "$OUTPUT_DIR/battery.diff" 2>&1 \
    || { cat "$OUTPUT_DIR/battery.diff" | head -10; fail "committed battery slices differ from regenerated (ranges.inc drift? regenerate + re-baseline with justification)"; }
NPOINTS=$(grep -h '#define BATTERY_N' "$BATTERY_DIR"/*.c | grep -oE '[0-9]+' | paste -sd+ | bc)
echo "[prep] committed battery matches generator output ($(ls "$BATTERY_DIR" | wc -l) slices, $NPOINTS points)"

# --- 3. collect slices ------------------------------------------------------
declare -a SLICES=()
if [[ ${#ONLY[@]} -gt 0 ]]; then
    for s in "${ONLY[@]}"; do
        [[ -f "$BATTERY_DIR/${s%.c}.c" ]] || fail "no such slice: $s"
        SLICES+=("$BATTERY_DIR/${s%.c}.c")
    done
else
    while IFS= read -r f; do SLICES+=("$f"); done < <(find "$BATTERY_DIR" -name 'chvalid_battery_*.c' | sort)
fi
[[ ${#SLICES[@]} -gt 0 ]] || fail "no battery slices found (empty battery is a failure)"

# --- 4. chvalid.c cabs-json (once) ------------------------------------------
CHVALID_JSON="$OUTPUT_DIR/chvalid.json"
jexit=0
( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
    "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "${FLAGS[@]}" "$CHVALID_TU" \
    > "$CHVALID_JSON" 2> "$OUTPUT_DIR/json.err" ) || jexit=$?
[[ $jexit -eq 0 && -s "$CHVALID_JSON" ]] || fail "cabs-json failed for chvalid.c (exit $jexit): $(tail -2 "$OUTPUT_DIR/json.err" | tr '\n' ' ')"

# --- 5. per-slice differential ----------------------------------------------
resource_of() { # <err-file> -> "wall=... maxRSS=...kB"
    echo "wall=$(grep -oE 'Elapsed \(wall clock\) time.*' "$1" | awk '{print $NF}') maxRSS=$(grep -oE 'Maximum resident set size \(kbytes\): [0-9]+' "$1" | awk '{print $NF}')kB"
}

PASS=0
FAIL_CNT=0
: > "$OUTPUT_DIR/baseline.new"
for slice in "${SLICES[@]}"; do
    sname=$(basename "$slice" .c)

    # OCaml oracle (single-trace random mode)
    cerb_exit=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" /usr/bin/time -v \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --nolibc --exec --batch \
        "${FLAGS[@]}" "$slice" "$CHVALID_TU" \
        > "$OUTPUT_DIR/$sname.ocaml.out" 2> "$OUTPUT_DIR/$sname.ocaml.err" ) || cerb_exit=$?
    cerb_output=$(cat "$OUTPUT_DIR/$sname.ocaml.out")
    if [[ $cerb_exit -eq 137 ]]; then
        echo "[$sname] FAIL: OCaml $(kill_label 137 "$OUTPUT_DIR/$sname.ocaml.err")"
        FAIL_CNT=$((FAIL_CNT+1)); continue
    fi
    if [[ $cerb_exit -ge 124 || -z "$cerb_output" ]]; then
        echo "[$sname] FAIL: OCaml timeout/crash (exit $cerb_exit): $(tail -2 "$OUTPUT_DIR/$sname.ocaml.err" | tr '\n' ' ')"
        FAIL_CNT=$((FAIL_CNT+1)); continue
    fi
    if [[ "$cerb_output" != Defined\ \{* || $cerb_exit -ne 0 ]]; then
        echo "[$sname] FAIL: OCaml verdict/exit anomaly (exit $cerb_exit): $(echo "$cerb_output" | head -1)"
        FAIL_CNT=$((FAIL_CNT+1)); continue
    fi
    echo "$sname: $cerb_output" >> "$OUTPUT_DIR/baseline.new"

    # oracle vs committed baseline
    if ! $RECORD_BASELINE; then
        expected=$(grep -F "$sname: " "$BASELINE" | head -1)
        if [[ -z "$expected" ]]; then
            echo "[$sname] FAIL: no baseline entry"
            FAIL_CNT=$((FAIL_CNT+1)); continue
        fi
        if [[ "$expected" != "$sname: $cerb_output" ]]; then
            echo "[$sname] FAIL: oracle drifted from committed baseline:"
            echo "    baseline: ${expected#"$sname": }"
            echo "    oracle:   $cerb_output"
            FAIL_CNT=$((FAIL_CNT+1)); continue
        fi
    fi

    # slice cabs-json
    jexit=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "${FLAGS[@]}" "$slice" \
        > "$OUTPUT_DIR/$sname.json" 2> "$OUTPUT_DIR/json.err" ) || jexit=$?
    if [[ $jexit -ne 0 || ! -s "$OUTPUT_DIR/$sname.json" ]]; then
        echo "[$sname] FAIL: cabs-json (exit $jexit)"
        FAIL_CNT=$((FAIL_CNT+1)); continue
    fi

    # Lean pipeline (single-trace)
    lean_exit=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" /usr/bin/time -v \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch --first \
        "$OUTPUT_DIR/$sname.json" "$CHVALID_JSON" \
        > "$OUTPUT_DIR/$sname.lean.out" 2> "$OUTPUT_DIR/$sname.lean.err" ) || lean_exit=$?
    lean_output=$(cat "$OUTPUT_DIR/$sname.lean.out")
    if [[ $lean_exit -eq 137 ]]; then
        echo "[$sname] FAIL: Lean $(kill_label 137 "$OUTPUT_DIR/$sname.lean.err")"
        FAIL_CNT=$((FAIL_CNT+1)); continue
    fi
    if [[ $lean_exit -ge 124 ]]; then
        echo "[$sname] FAIL: Lean timeout/crash (exit $lean_exit): $(tail -2 "$OUTPUT_DIR/$sname.lean.err" | tr '\n' ' ')"
        FAIL_CNT=$((FAIL_CNT+1)); continue
    fi
    if [[ $lean_exit -ne 0 ]]; then
        echo "[$sname] FAIL: Lean exit $lean_exit: $(echo "$lean_output" | head -1)"
        FAIL_CNT=$((FAIL_CNT+1)); continue
    fi
    rm -f "$OUTPUT_DIR/$sname.json"

    # full-line comparison (checksum value + stdout + stderr + blocked)
    if [[ "$lean_output" == "$cerb_output" ]]; then
        echo "[$sname] MATCH ($(resource_of "$OUTPUT_DIR/$sname.ocaml.err") | lean $(resource_of "$OUTPUT_DIR/$sname.lean.err"))"
        PASS=$((PASS+1))
    else
        echo "[$sname] MISMATCH:"
        echo "    ocaml: $cerb_output"
        echo "    lean:  $lean_output"
        echo "    minimize: gen_chvalid_battery.py --slice A:B / --verbose-point 0xN"
        FAIL_CNT=$((FAIL_CNT+1))
    fi
done

echo ""
echo "=================================================="
echo "SUMMARY: total=$((PASS+FAIL_CNT)) match=$PASS fail=$FAIL_CNT (points: $NPOINTS, 22 observations each)"
if [[ $FAIL_CNT -gt 0 ]]; then
    exit 1
fi
if $RECORD_BASELINE; then
    mv "$OUTPUT_DIR/baseline.new" "$BASELINE"
    echo "BASELINE RECORDED: $BASELINE ($(wc -l < "$BASELINE") entries)"
fi
echo "ALL PASSED"
exit 0
