#!/bin/bash
# test_libxml2_uri.sh — arc-6 S4 GATE (charter success condition 1;
# formerly the arc-5 S3 stretch harness / arc-6 S1 reporting baseline).
#
# The probe's 4-TU xmlParseURISafe execution datapoint
# (notes/2026-08-19_libxml2-probe.md, "Execution datapoint"), extended to a
# 16-URI corpus (tests/libxml2/uri_harness.c: valid / invalid / edge cases;
# arc-6 S4 grew it 10 → 16 with RFC 3986 edge classes — IPv6 literal,
# empty components, scheme-only, lone fragment, pct-encoded reserved chars,
# empty authority) and run against FOUR lanes, each recorded in the
# committed baseline (tests/libxml2/uri_baseline.txt):
#
#   ORACLE_LIBC   : OCaml cerberus WITH its C libc (the probe's invocation;
#                   no --nolibc). Executes the full corpus — the hard
#                   ceiling. Single-trace default --mode=random.
#   OCAML_NOLIBC  : OCaml cerberus --nolibc. Fails at exec: uri.c's closure
#                   needs memset (via the libc .core), which --nolibc
#                   excludes.
#   LEAN_NOLIBC   : cerberus-lean --batch --first over the 5 cabs-jsons,
#                   no C library (only the core stdlib). Mirrors
#                   OCAML_NOLIBC: identical Symbol(118, SD_Id("memset"))
#                   unknown-procedure failure — kept as the recorded
#                   mirrored-failure pair documenting that the --nolibc
#                   surfaces still agree. (--first returns
#                   branch-index-0's trace; see CerbND.runND1.)
#   LEAN_LIBC     : arc-6 S1 — cerberus-lean --batch --first with the C
#                   library loaded (--libc <pinned tests/libc/libc.core>
#                   + the 12 metadata TU cabs-jsons from
#                   libc_prep.sh --jsons; see Main.loadLibc for the
#                   bodies/metadata split and citations). Differential
#                   against ORACLE_LIBC: byte-for-byte agreement on the
#                   full N-URI corpus is the arc-6 exit criterion.
#
# GATING (arc-6 S4, charter success condition 1) — fail-closed, exit 1 on
# ANY of:
#   * lane-expectation violation (each lane's expectation is PINNED in
#     this script, independent of the baseline file):
#       ORACLE_LIBC   exit 0, Defined/Specified verdict, corpus-size pin
#                     ("uri_harness n=16 h=" in its stdout)
#       OCAML_NOLIBC  exit 1, unknown-procedure memset failure
#       LEAN_NOLIBC   exit 1, unknown-procedure memset failure (the
#                     mirrored-failure pair: both --nolibc surfaces must
#                     KEEP agreeing that memset is the missing symbol)
#       LEAN_LIBC     exit 0 AND verdict line byte-identical to
#                     ORACLE_LIBC (the 16/16 differential bar)
#   * drift from the committed baseline in EITHER direction (a regression
#     or an unrecorded improvement both demand a baseline update with
#     justification).
#   The lane expectations are enforced in --record-baseline mode too — a
#   re-record cannot launder a broken lane.
#
# Usage: ./scripts/test_libxml2_uri.sh [--record-baseline]
# Environment: TIMEOUT_SECS (default 300), LIBXML2_DIR (see libxml2_prep.sh)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-300}"
ULIMIT_KB=4000000
N_URIS=16   # corpus-size pin: must match NTESTS in tests/libxml2/uri_harness.c

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
echo "libxml2 uri 5-TU harness (arc-6 S4 GATE, $N_URIS-URI corpus)"
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
# Lane expectation (pinned): successful Defined/Specified run over the full
# pinned corpus size.
oracle_line=$(head -1 "$OUTPUT_DIR/oracle.out")
[[ $rc -eq 0 ]] || fail "GATE: ORACLE_LIBC expected exit 0, got $rc"
[[ "$oracle_line" == 'Defined {value: "Specified('* ]] \
    || fail "GATE: ORACLE_LIBC verdict is not Defined/Specified: ${oracle_line:0:120}"
[[ "$oracle_line" == *"uri_harness n=$N_URIS h="* ]] \
    || fail "GATE: ORACLE_LIBC corpus-size pin violated (expected uri_harness n=$N_URIS in stdout)"

# --- OCAML_NOLIBC -----------------------------------------------------------
rc=0
run_capped "$OUTPUT_DIR/nolibc.out" "$OUTPUT_DIR/nolibc.err" \
    "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --nolibc --exec --batch \
    "${FLAGS[@]}" "${TUS[@]}" || rc=$?
[[ $rc -lt 124 ]] || fail "OCAML_NOLIBC timeout/crash (exit $rc)"
record "OCAML_NOLIBC exit" "$rc"
record "OCAML_NOLIBC" "$(head -1 "$OUTPUT_DIR/nolibc.out")"
echo "[ocaml-nolibc] exit=$rc: $(head -c 100 "$OUTPUT_DIR/nolibc.out")"
# Lane expectation (pinned): the recorded --nolibc failure mode — memset is
# the closure's missing symbol.
ocaml_nolibc_line=$(head -1 "$OUTPUT_DIR/nolibc.out")
[[ $rc -eq 1 ]] || fail "GATE: OCAML_NOLIBC expected exit 1, got $rc"
[[ "$ocaml_nolibc_line" == *'unknown procedure'* && "$ocaml_nolibc_line" == *'memset'* ]] \
    || fail "GATE: OCAML_NOLIBC expected unknown-procedure memset failure, got: ${ocaml_nolibc_line:0:120}"

# --- LEAN_NOLIBC ------------------------------------------------------------
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
[[ $rc -lt 124 ]] || fail "LEAN_NOLIBC timeout/crash (exit $rc): $(tail -2 "$OUTPUT_DIR/lean.err" | tr '\n' ' ')"
record "LEAN_NOLIBC exit" "$rc"
record "LEAN_NOLIBC" "$(head -1 "$OUTPUT_DIR/lean.out")"
echo "[lean-nolibc] exit=$rc wall=$(grep -oE 'Elapsed.*' "$OUTPUT_DIR/lean.err" | awk '{print $NF}') maxRSS=$(grep 'Maximum resident' "$OUTPUT_DIR/lean.err" | awk '{print $NF}')kB: $(head -c 100 "$OUTPUT_DIR/lean.out")"
# Lane expectation (pinned): the MIRRORED-FAILURE PAIR — the Lean --nolibc
# surface must keep agreeing with OCAML_NOLIBC that memset is the missing
# symbol.
lean_nolibc_line=$(head -1 "$OUTPUT_DIR/lean.out")
[[ $rc -eq 1 ]] || fail "GATE: LEAN_NOLIBC expected exit 1, got $rc"
[[ "$lean_nolibc_line" == *'unknown procedure'* && "$lean_nolibc_line" == *'memset'* ]] \
    || fail "GATE: LEAN_NOLIBC expected unknown-procedure memset failure (mirroring OCAML_NOLIBC), got: ${lean_nolibc_line:0:120}"

# --- LEAN_LIBC (arc-6 S1) ---------------------------------------------------
# The pinned libc dump (drift-checked by libc_prep.sh) + the 12 metadata
# TU cabs-jsons, linked BEFORE the user TUs (Main.loadLibc / runPipeline;
# mirrors main.ml:150-156 core_libraries-first order).
mapfile -t LIBC_JSONS < <("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$OUTPUT_DIR/libcjson") \
    || fail "libc_prep.sh --jsons failed (pin drift or oracle missing)"
[[ ${#LIBC_JSONS[@]} -eq 12 ]] || fail "expected 12 libc metadata jsons, got ${#LIBC_JSONS[@]}"
LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
rc=0
run_capped "$OUTPUT_DIR/lean_libc.out" "$OUTPUT_DIR/lean_libc.err" \
    env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch --first "${LIBC_ARGS[@]}" "${JSONS[@]}" || rc=$?
[[ $rc -lt 124 ]] || fail "LEAN_LIBC timeout/crash (exit $rc): $(tail -2 "$OUTPUT_DIR/lean_libc.err" | tr '\n' ' ')"
record "LEAN_LIBC exit" "$rc"
record "LEAN_LIBC" "$(head -1 "$OUTPUT_DIR/lean_libc.out")"
echo "[lean+libc] exit=$rc wall=$(grep -oE 'Elapsed.*' "$OUTPUT_DIR/lean_libc.err" | awk '{print $NF}') maxRSS=$(grep 'Maximum resident' "$OUTPUT_DIR/lean_libc.err" | awk '{print $NF}')kB: $(head -c 100 "$OUTPUT_DIR/lean_libc.out")"
# Lane expectation (pinned): THE GATE — byte-identical verdict line vs
# ORACLE_LIBC over the full corpus (charter success condition 1).
lean_libc_line=$(head -1 "$OUTPUT_DIR/lean_libc.out")
[[ $rc -eq 0 ]] || fail "GATE: LEAN_LIBC expected exit 0, got $rc"
if [[ "$lean_libc_line" == "$oracle_line" ]]; then
    echo "[lean+libc] EXACT MATCH with ORACLE_LIBC ($N_URIS/$N_URIS URI corpus)"
else
    echo "[lean+libc] MISMATCH with ORACLE_LIBC:" >&2
    echo "  oracle: ${oracle_line:0:200}" >&2
    echo "  lean:   ${lean_libc_line:0:200}" >&2
    fail "GATE: LEAN_LIBC differential mismatch vs ORACLE_LIBC"
fi

# --- compare against the committed baseline (gate leg 2: drift) -------------
# All pinned lane expectations passed above (they run in --record-baseline
# mode too — a re-record cannot launder a broken lane).
echo ""
if $RECORD_BASELINE; then
    mv "$OUTPUT_DIR/baseline.new" "$BASELINE"
    echo "BASELINE RECORDED: $BASELINE"
    cat "$BASELINE"
    exit 0
fi
if diff -u "$BASELINE" "$OUTPUT_DIR/baseline.new" > "$OUTPUT_DIR/baseline.diff"; then
    echo "=================================================="
    echo "GATE PASS: all lane expectations pinned-green + baseline unchanged ($N_URIS/$N_URIS)"
    exit 0
else
    echo "GATE FAIL: drift from committed baseline (regression OR unrecorded improvement):"
    cat "$OUTPUT_DIR/baseline.diff"
    exit 1
fi
