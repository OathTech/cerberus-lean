#!/bin/bash
# test_libxml2_uri.sh — arc-5 S3 STRETCH harness / arc-6 REPORTING baseline.
#
# The probe's 4-TU xmlParseURISafe execution datapoint
# (notes/2026-08-19_libxml2-probe.md, "Execution datapoint"), extended to a
# 10-URI corpus (tests/libxml2/uri_harness.c: valid / invalid / edge cases)
# and run against THREE configurations, each recorded in the committed
# baseline (tests/libxml2/uri_baseline.txt):
#
#   ORACLE_LIBC   : OCaml cerberus WITH its C libc (the probe's invocation;
#                   no --nolibc). Executes the full corpus — the hard
#                   ceiling. Single-trace default --mode=random.
#   OCAML_NOLIBC  : OCaml cerberus --nolibc. Fails at exec: uri.c's closure
#                   needs memset (via the libc .core), which --nolibc
#                   excludes. This is the surface the Lean pipeline mirrors.
#   LEAN          : cerberus-lean --batch --first over the 5 cabs-jsons.
#                   (--first returns branch-index-0's trace, which equals
#                   the LAST execution of the exhaustive list — exhaustive
#                   mirrors OCaml's prepend order — NOT exhaustive's
#                   execution 0; see CerbND.runND1.)
#                   The Lean pipeline links no C library (only the core
#                   stdlib — test_exec.sh parity choice), so the EXPECTED
#                   2026-08-19 state is exec failure on the SAME unknown
#                   procedure symbol as OCAML_NOLIBC (measured: identical
#                   Symbol(118, SD_Id("memset")) both sides — the 5-TU
#                   frontend+link itself succeeds on the Lean side in ~2 s).
#
# This is a REPORTING baseline, not a pass/fail capability bar: the gate
# fails only if reality DRIFTS from the recorded baseline (fail-closed both
# directions — a regression or an unrecorded improvement both demand a
# baseline update with justification). When arc 6 lands C-libc loading in
# the Lean pipeline, LEAN/OCAML_NOLIBC advance and this baseline is updated.
#
# Usage: ./scripts/test_libxml2_uri.sh [--record-baseline]
# Environment: TIMEOUT_SECS (default 300), LIBXML2_DIR (see libxml2_prep.sh)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-300}"
ULIMIT_KB=4000000

RECORD_BASELINE=false
[[ "${1:-}" == "--record-baseline" ]] && RECORD_BASELINE=true

command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }

BASELINE="$PROJECT_ROOT/tests/libxml2/uri_baseline.txt"
HARNESS="$PROJECT_ROOT/tests/libxml2/uri_harness.c"

fail() { echo "FAIL: $*" >&2; exit 1; }

build_cerberus
build_lean

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR"
[[ -f "$HARNESS" ]] || fail "harness not found: $HARNESS"
$RECORD_BASELINE || [[ -f "$BASELINE" ]] || fail "baseline not found: $BASELINE"

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/libxml2-uri.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"
cd "$PROJECT_ROOT" || fail "cannot cd to $PROJECT_ROOT"

echo ""
echo "libxml2 uri 5-TU stretch harness (arc-6 reporting baseline)"
echo "=================================================="

mapfile -t PREP < <("$PROJECT_ROOT/scripts/libxml2_prep.sh" uri.c) \
    || fail "libxml2_prep.sh failed"
URI_TU="${PREP[${#PREP[@]}-1]}"
FLAGS=("${PREP[@]:0:${#PREP[@]}-1}")
LIBXML2_ROOT="$(dirname "$URI_TU")"
TUS=("$HARNESS" "$URI_TU" "$LIBXML2_ROOT/xmlstring.c" "$LIBXML2_ROOT/xmlmemory.c" "$LIBXML2_ROOT/globals.c")
for t in "${TUS[@]}"; do [[ -f "$t" ]] || fail "missing TU: $t"; done
echo "[prep] pins verified; 5 TUs"

run_capped() { # <out> <err> <cmd...>
    local out="$1" err="$2"; shift 2
    local rc=0
    ( ulimit -v $ULIMIT_KB; exec timeout "${TIMEOUT_SECS}s" /usr/bin/time -v "$@" \
        > "$out" 2> "$err" ) || rc=$?
    return $rc
}

: > "$OUTPUT_DIR/baseline.new"
record() { echo "$1: $2" >> "$OUTPUT_DIR/baseline.new"; }

# --- ORACLE_LIBC ------------------------------------------------------------
rc=0
run_capped "$OUTPUT_DIR/oracle.out" "$OUTPUT_DIR/oracle.err" \
    "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --exec --batch \
    "${FLAGS[@]}" "${TUS[@]}" || rc=$?
[[ $rc -lt 124 ]] || fail "ORACLE_LIBC timeout/crash (exit $rc)"
record "ORACLE_LIBC exit" "$rc"
record "ORACLE_LIBC" "$(head -1 "$OUTPUT_DIR/oracle.out")"
echo "[oracle+libc] exit=$rc wall=$(grep -oE 'Elapsed.*' "$OUTPUT_DIR/oracle.err" | awk '{print $NF}') maxRSS=$(grep 'Maximum resident' "$OUTPUT_DIR/oracle.err" | awk '{print $NF}')kB"

# --- OCAML_NOLIBC -----------------------------------------------------------
rc=0
run_capped "$OUTPUT_DIR/nolibc.out" "$OUTPUT_DIR/nolibc.err" \
    "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --nolibc --exec --batch \
    "${FLAGS[@]}" "${TUS[@]}" || rc=$?
[[ $rc -lt 124 ]] || fail "OCAML_NOLIBC timeout/crash (exit $rc)"
record "OCAML_NOLIBC exit" "$rc"
record "OCAML_NOLIBC" "$(head -1 "$OUTPUT_DIR/nolibc.out")"
echo "[ocaml-nolibc] exit=$rc: $(head -c 100 "$OUTPUT_DIR/nolibc.out")"

# --- LEAN -------------------------------------------------------------------
declare -a JSONS=()
for t in "${TUS[@]}"; do
    j="$OUTPUT_DIR/$(basename "$t" .c).json"
    rc=0
    ( ulimit -v $ULIMIT_KB; exec timeout "${TIMEOUT_SECS}s" \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "${FLAGS[@]}" "$t" \
        > "$j" 2> "$OUTPUT_DIR/json.err" ) || rc=$?
    [[ $rc -eq 0 && -s "$j" ]] || fail "cabs-json failed for $(basename "$t") (exit $rc)"
    JSONS+=("$j")
done
rc=0
run_capped "$OUTPUT_DIR/lean.out" "$OUTPUT_DIR/lean.err" \
    env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch --first "${JSONS[@]}" || rc=$?
[[ $rc -lt 124 ]] || fail "LEAN timeout/crash (exit $rc): $(tail -2 "$OUTPUT_DIR/lean.err" | tr '\n' ' ')"
record "LEAN exit" "$rc"
record "LEAN" "$(head -1 "$OUTPUT_DIR/lean.out")"
echo "[lean] exit=$rc wall=$(grep -oE 'Elapsed.*' "$OUTPUT_DIR/lean.err" | awk '{print $NF}') maxRSS=$(grep 'Maximum resident' "$OUTPUT_DIR/lean.err" | awk '{print $NF}')kB: $(head -c 100 "$OUTPUT_DIR/lean.out")"

# --- compare against the reporting baseline ---------------------------------
echo ""
if $RECORD_BASELINE; then
    mv "$OUTPUT_DIR/baseline.new" "$BASELINE"
    echo "BASELINE RECORDED: $BASELINE"
    cat "$BASELINE"
    exit 0
fi
if diff -u "$BASELINE" "$OUTPUT_DIR/baseline.new" > "$OUTPUT_DIR/baseline.diff"; then
    echo "=================================================="
    echo "ALL MATCH RECORDED BASELINE (arc-6 reporting state unchanged)"
    exit 0
else
    echo "DRIFT from recorded baseline (regression OR unrecorded improvement):"
    cat "$OUTPUT_DIR/baseline.diff"
    exit 1
fi
