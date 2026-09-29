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
# composition test. Both sides' complete batch observations must agree
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
# EXHAUSTIVE libc-mode rows (2026-09-28, thin-surface tests slice; before it
# every libc-mode lane row was single-trace): tests/libc_exec/exhaustive/*.c
# run with the oracle at `--mode=exhaustive` and Lean WITHOUT `--first`, and
# the complete ordered verdict sequences are compared (the codec's `full`
# tokens, as for every other row). Baseline rows are named
# `exhaustive/<name>`. Each exhaustive row carries a built-in NON-VACUITY
# PLANT, run on every lane pass: (a) the oracle's exhaustive observation must
# hold >= 2 executions, and (b) the same program re-run on Lean WITH
# `--first` must NOT compare equal to it. A row failing either is status
# VACUOUS (never MATCH): an exhaustive row that a single-trace run would also
# pass certifies nothing beyond the single-trace rows. (b) also witnesses
# that the comparator distinguishes the two modes on this very row.
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

mkdir -p "$OBSERVATION_RUN_DIR" || fail "cannot create raw evidence directory"
OUTPUT_DIR=$(mktemp -d "$OBSERVATION_RUN_DIR/libc-exec.XXXXXXXXXX") || fail "mktemp failed"
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

# Row list: single-trace rows (tests/libc_exec/*.c) then exhaustive rows
# (tests/libc_exec/exhaustive/*.c, header). An existing but EMPTY exhaustive
# directory is a harness failure, never a silently skipped mode.
declare -a ROWS=()
for tu in "$PROJECT_ROOT"/tests/libc_exec/*.c; do ROWS+=("first|$tu"); done
EXH_DIR="$PROJECT_ROOT/tests/libc_exec/exhaustive"
if [[ -d "$EXH_DIR" ]]; then
    compgen -G "$EXH_DIR/*.c" > /dev/null || fail "empty exhaustive corpus: $EXH_DIR"
    for tu in "$EXH_DIR"/*.c; do ROWS+=("exhaustive|$tu"); done
fi

: > "$OUTPUT_DIR/baseline.new"
pass=0; failcnt=0
for row in "${ROWS[@]}"; do
    mode="${row%%|*}"; tu="${row#*|}"
    if [[ "$mode" == exhaustive ]]; then
        name="exhaustive/$(basename "$tu" .c)"
        ORACLE_MODE=(--mode=exhaustive); LEAN_MODE=()
    else
        name="$(basename "$tu" .c)"
        ORACLE_MODE=(); LEAN_MODE=(--first)
    fi
    f="${name//\//__}"   # capture-file stem
    # OCaml side: WITH libc (no --nolibc)
    rc=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --exec --batch "${ORACLE_MODE[@]}" "$tu" \
        > "$OUTPUT_DIR/$f.ocaml" 2> "$OUTPUT_DIR/$f.ocaml.err" ) || rc=$?
    ocaml_rc=$rc
    printf '%s\n' "$ocaml_rc" > "$OUTPUT_DIR/$f.ocaml.status"
    ocaml_line="$(cat "$OUTPUT_DIR/$f.ocaml")"
    # cabs-json (same flags as the standing harnesses: no --nolibc — the
    # cpp side is identical between oracle and Lean, S0 survey §b)
    rc=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "$tu" \
        > "$OUTPUT_DIR/$f.json" 2> "$OUTPUT_DIR/$f.json.err" ) || rc=$?
    printf '%s\n' "$rc" > "$OUTPUT_DIR/$f.json.status"
    [[ $rc -eq 0 && -s "$OUTPUT_DIR/$f.json" ]] || fail "cabs-json failed for $name"
    # Lean side: --libc mode (--first on single-trace rows only)
    rc=0
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch "${LEAN_MODE[@]}" \
        "${LIBC_ARGS[@]}" "$OUTPUT_DIR/$f.json" \
        > "$OUTPUT_DIR/$f.lean" 2> "$OUTPUT_DIR/$f.lean.err" ) || rc=$?
    printf '%s\n' "$rc" > "$OUTPUT_DIR/$f.lean.status"
    lean_line="$(cat "$OUTPUT_DIR/$f.lean")"
    if is_cap_kill $rc "$OUTPUT_DIR/$f.lean.err" || is_cap_kill $ocaml_rc "$OUTPUT_DIR/$f.ocaml.err"; then
        # memory-cap breach on either side (capped OOM-KILLED witness): its
        # own status, never MATCH
        status="KILL"
        failcnt=$((failcnt+1))
        killed_side=""
        is_cap_kill $ocaml_rc "$OUTPUT_DIR/$f.ocaml.err" && killed_side="oracle: $(kill_label $ocaml_rc "$OUTPUT_DIR/$f.ocaml.err")"
        is_cap_kill $rc "$OUTPUT_DIR/$f.lean.err" && killed_side="${killed_side:+$killed_side; }lean: $(kill_label $rc "$OUTPUT_DIR/$f.lean.err")"
        echo "  KILL  $name: oracle exit $ocaml_rc, lean exit $rc — $killed_side"
    elif otok=$(python3 "$OBSERVATION_CODEC" tokens --stdout "$OUTPUT_DIR/$f.ocaml" \
                --stderr "$OUTPUT_DIR/$f.ocaml.err" --status "$ocaml_rc") && \
         ltok=$(python3 "$OBSERVATION_CODEC" tokens --stdout "$OUTPUT_DIR/$f.lean" \
                --stderr "$OUTPUT_DIR/$f.lean.err" --status "$rc") && \
         [[ "$otok" == "$ltok" ]]; then
        status="MATCH"
        if [[ "$mode" == exhaustive ]]; then
            # Non-vacuity plant (header): (a) >= 2 oracle executions; (b) a
            # Lean --first run of the same program must NOT compare equal.
            nexec=$(grep -c '' <<<"$otok")
            prc=0
            ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
                env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch --first \
                "${LIBC_ARGS[@]}" "$OUTPUT_DIR/$f.json" \
                > "$OUTPUT_DIR/$f.plant" 2> "$OUTPUT_DIR/$f.plant.err" ) || prc=$?
            ptok=$(python3 "$OBSERVATION_CODEC" tokens --stdout "$OUTPUT_DIR/$f.plant" \
                    --stderr "$OUTPUT_DIR/$f.plant.err" --status "$prc") \
                || fail "exhaustive plant: Lean --first run of $name gave no complete observation (exit $prc)"
            if [[ $nexec -lt 2 ]]; then
                status="VACUOUS"
                echo "  VACUOUS $name: oracle exhaustive observation has $nexec execution(s) (< 2)"
            elif [[ "$ptok" == "$otok" ]]; then
                status="VACUOUS"
                echo "  VACUOUS $name: the Lean --first observation equals the exhaustive one"
            else
                echo "  PLANT $name: exhaustive $nexec verdicts; Lean --first $(grep -c '' <<<"$ptok") verdict(s) — differs, as required"
            fi
        fi
        if [[ "$status" == MATCH ]]; then
            pass=$((pass+1))
            echo "  MATCH $name: $(head -c 80 <<<"$ocaml_line")"
        else
            failcnt=$((failcnt+1))
        fi
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
# A VACUOUS row is never acceptable, recorded or not (pre-merge audit F8,
# 2026-09-29: a VACUOUS status written into the baseline used to diff clean
# and print ALL MATCH): an exhaustive row must actually exercise >= 2
# executions and differ from --first, or it is not evidence.
if grep -q ' VACUOUS$' "$OUTPUT_DIR/baseline.new" || grep -q ' VACUOUS$' "$BASELINE" 2>/dev/null; then
    echo "FAILED: VACUOUS exhaustive row(s) — never admissible, recorded or current:"
    grep ' VACUOUS$' "$OUTPUT_DIR/baseline.new" "$BASELINE" 2>/dev/null
    exit 1
fi
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
