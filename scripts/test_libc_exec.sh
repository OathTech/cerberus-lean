#!/bin/bash
# test_libc_exec.sh — arc-6 S1 differential: C programs with REAL libc
# dependencies, executed with the C library loaded on BOTH sides.
#
# This is a NEW, additive mode (arc-6 charter: libc-enabled runs are new
# harness modes with their own baselines — the standing minimal/coverage/
# debug corpora keep their --nolibc flags and baselines untouched).
#
#   OCaml : cerberus --exec --batch          (NO --nolibc — the oracle
#           loads runtime/libc/libc.co as a library first,
#           backend/driver/main.ml:150-156)
#   Lean  : cerberus-lean --batch --first --libc <pinned dump>
#           --libc-tu <12 metadata cabs-jsons>   (Main.loadLibc mirror;
#           see scripts/libc_prep.sh for the two-artifact trust story)
#
# Corpus: tests/libc_exec/*.c — the S0 survey's coverage libc wants
# (exit/puts/calloc/memset/strlen, survey §a.3) plus a snprintf
# composition test. Both sides' first batch line must agree exactly
# (value + stdout + stderr). Committed baseline:
# tests/libc_exec/baseline.txt (fail-closed both directions, the
# uri-baseline pattern).
#
# S1 KNOWN DIFF, CLOSED IN S2: 006-strlen-snprintf was the recorded
# varargs frontier (libc snprintf va_start → builtin vsnprintf →
# formatted.lem:797 Mem.va_list → CerbMem stubs, register 15). Arc-6 S2
# implemented the five varargs memops in CerbMem mirroring
# impl_mem.ml:2698-2764 (prototype port Step.lean:1441-1513 attributed);
# 006 now MATCHes (Specified(18), the D10-predicted deliberate drift) —
# baseline re-recorded 6/6 MATCH. 007-va-user-vsnprintf added in S2:
# a USER variadic wrapper (va_start → va_list-as-value → libc vsnprintf)
# composing memop-varargs with the Formatted path in one trace.
#
# Usage: ./scripts/test_libc_exec.sh [--record-baseline]
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-300}"
# Per-test memory cap: `scripts/capped` at CERB_TEST_MEM_MAX (default 4G,
# cgroup RSS; common.sh CAPPED_TEST) — mem-scale S2 (2026-09-02, Q2 [USER
# 2026-09-02]) replacing the arc-5 `ulimit -v 4000000`. A cap breach (exit
# 137 + capped's OOM-KILLED witness banner) is status KILL, never MATCH.

RECORD_BASELINE=false
[[ "${1:-}" == "--record-baseline" ]] && RECORD_BASELINE=true

command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }

BASELINE="$PROJECT_ROOT/tests/libc_exec/baseline.txt"
fail() { echo "FAIL: $*" >&2; exit 1; }

build_cerberus
build_lean

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR"
$RECORD_BASELINE || [[ -f "$BASELINE" ]] || fail "baseline not found: $BASELINE (run --record-baseline)"

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/libc-exec.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"
cd "$PROJECT_ROOT" || fail "cannot cd to $PROJECT_ROOT"

echo ""
echo "libc exec differential (arc-6 S1: both sides load the C library)"
echo "=================================================="

# Pin drift-check + the 12 metadata cabs-jsons (libc_prep.sh fail-closed)
# NOTE: not `mapfile -t X < <(cmd) || fail` — mapfile succeeds even when
# the process-substituted cmd fails, so that guard is dead (arc-6 S5f
# audit fix; S2-arc-5 pattern: capture rc explicitly, then split).
libc_jsons_out=$("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$OUTPUT_DIR/libcjson") \
    || fail "libc_prep.sh --jsons failed (pin drift or oracle missing)"
[[ -n "$libc_jsons_out" ]] || fail "libc_prep.sh --jsons emitted no paths"
mapfile -t LIBC_JSONS <<< "$libc_jsons_out"
[[ ${#LIBC_JSONS[@]} -eq 12 ]] || fail "expected 12 libc metadata jsons, got ${#LIBC_JSONS[@]}"
LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
echo "[prep] libc pin verified; 12 metadata TUs"

: > "$OUTPUT_DIR/baseline.new"
pass=0; failcnt=0
for tu in "$PROJECT_ROOT"/tests/libc_exec/*.c; do
    name="$(basename "$tu" .c)"
    # OCaml side: WITH libc (no --nolibc)
    rc=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --exec --batch "$tu" \
        > "$OUTPUT_DIR/$name.ocaml" 2> "$OUTPUT_DIR/$name.ocaml.err" ) || rc=$?
    ocaml_rc=$rc
    ocaml_line="$(head -1 "$OUTPUT_DIR/$name.ocaml")"
    # cabs-json (same flags as the standing harnesses: no --nolibc — the
    # cpp side is identical between oracle and Lean, S0 survey §b)
    rc=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "$tu" \
        > "$OUTPUT_DIR/$name.json" 2> /dev/null ) || rc=$?
    [[ $rc -eq 0 && -s "$OUTPUT_DIR/$name.json" ]] || fail "cabs-json failed for $name"
    # Lean side: --libc mode
    rc=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch --first \
        "${LIBC_ARGS[@]}" "$OUTPUT_DIR/$name.json" \
        > "$OUTPUT_DIR/$name.lean" 2> "$OUTPUT_DIR/$name.lean.err" ) || rc=$?
    lean_line="$(head -1 "$OUTPUT_DIR/$name.lean")"
    if is_cap_kill $rc "$OUTPUT_DIR/$name.lean.err" || is_cap_kill $ocaml_rc "$OUTPUT_DIR/$name.ocaml.err"; then
        # memory-cap breach on either side (capped OOM-KILLED witness): its
        # own status, never MATCH
        status="KILL"
        failcnt=$((failcnt+1))
        killed_side=""
        is_cap_kill $ocaml_rc "$OUTPUT_DIR/$name.ocaml.err" && killed_side="oracle: $(kill_label $ocaml_rc "$OUTPUT_DIR/$name.ocaml.err")"
        is_cap_kill $rc "$OUTPUT_DIR/$name.lean.err" && killed_side="${killed_side:+$killed_side; }lean: $(kill_label $rc "$OUTPUT_DIR/$name.lean.err")"
        echo "  KILL  $name: oracle exit $ocaml_rc, lean exit $rc — $killed_side"
    elif [[ "$ocaml_line" == "$lean_line" && -n "$ocaml_line" ]]; then
        status="MATCH"
        pass=$((pass+1))
        echo "  MATCH $name: $(head -c 80 <<<"$ocaml_line")"
    else
        status="DIFF"
        failcnt=$((failcnt+1))
        echo "  DIFF  $name:"
        echo "    O: $ocaml_line"
        echo "    L: $lean_line"
    fi
    echo "$name $status" >> "$OUTPUT_DIR/baseline.new"
done

echo ""
echo "SUMMARY: match=$pass diff=$failcnt"
if $RECORD_BASELINE; then
    mv "$OUTPUT_DIR/baseline.new" "$BASELINE"
    echo "BASELINE RECORDED: $BASELINE"
    cat "$BASELINE"
    exit 0
fi
if diff -u "$BASELINE" "$OUTPUT_DIR/baseline.new" > "$OUTPUT_DIR/baseline.diff"; then
    echo "ALL MATCH RECORDED BASELINE"
    exit 0
else
    echo "DRIFT from recorded baseline (regression OR unrecorded improvement):"
    cat "$OUTPUT_DIR/baseline.diff"
    exit 1
fi
