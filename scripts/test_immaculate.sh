#!/bin/bash
# test_immaculate.sh — arc-14 (the immaculate pass) TEST-FIRST lane.
#
# Targeted differential probes for the latent-wrong-answer GRAVE/SERIOUS
# items in the two grumpy-professor registers
# (notes/2026-08-21_grumpy-audit-cerberus-semantics.md and
#  .../grumpy-audit-lem-backend.md). These findings are latent precisely
# because the standing corpora never exercise the failing inputs; this
# lane exercises them NOW, records the honest CURRENT-tree failures as its
# baseline, and each S1/S2 fix flips a row.
#
# THE HONEST BASELINE (charter S0 centerpiece): the committed baseline
# (tests/immaculate/baseline.txt) records the CURRENT, mostly-FAILING
# state. DIFF / ORACLE_CRASH / CONFLATED rows are EXPECTED — they are the
# S0 baseline the fixes will flip, NOT gate failures. This script is
# fail-closed against that baseline: any status that differs from the
# recorded one (a regression on a MATCH row, OR a fix flipping a DIFF to
# MATCH) exits nonzero, forcing a deliberate, justified re-record when a
# fix lands (the test_exec.sh / uri-baseline discipline).
#
# Corpora:
#   tests/immaculate/nolibc/*.c  — oracle --exec --batch --nolibc  vs
#                                  Lean pipeline --batch --first
#   tests/immaculate/libc/*.c    — oracle --exec --batch (libc loaded) vs
#                                  Lean --batch --first --libc <dump> --libc-tu…
#   tests/immaculate/g6-hash-collision.lean — in-Lean CoreParser symbol
#                                  conflation probe (no oracle side)
#
# Comparison is on the SEMANTIC VERDICT TOKEN (UB code / value / error /
# crash), normalized to ignore source locations and timing (the loc field
# legitimately differs — Lean emits "unknown location"). This mirrors
# test_exec.sh's token approach.
#
# Usage: ./scripts/test_immaculate.sh [--record-baseline]
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

TIMEOUT_SECS="${TIMEOUT_SECS:-60}"
ULIMIT_KB=4000000

RECORD_BASELINE=false
[[ "${1:-}" == "--record-baseline" ]] && RECORD_BASELINE=true

command -v timeout &>/dev/null || { echo "Error: 'timeout' not found" >&2; exit 1; }

CORPUS="$PROJECT_ROOT/tests/immaculate"
BASELINE="$CORPUS/baseline.txt"
fail() { echo "FAIL: $*" >&2; exit 1; }

$RECORD_BASELINE || [[ -f "$BASELINE" ]] || fail "baseline not found: $BASELINE (run --record-baseline)"

build_cerberus
build_lean

RUNTIME_DIR="$PROJECT_ROOT/_build/install/default"
[[ -d "$RUNTIME_DIR" ]] || fail "runtime dir not found: $RUNTIME_DIR"

OUTPUT_DIR=$(mktemp -d "$TMP_DIR/immaculate.XXXXXXXXXX") || fail "mktemp failed"
register_cleanup "$OUTPUT_DIR"
cd "$PROJECT_ROOT" || fail "cannot cd to $PROJECT_ROOT"

# --- Normalize a batch first-line into a location/timing-free token. ---
# Undefined {ub: "CODE", ...}  -> UB:CODE
# Defined   {value: "VAL", ...}-> VAL:VAL
# Error     {msg: "MSG"}       -> ERR:MSG
# empty / uncaught exception / panic (with nonzero/crash exit) -> CRASH
verdict() {
    local line="$1" rc="$2"
    if [[ -z "$line" ]]; then
        # empty stdout: an oracle-side uncaught exception (exit 125/2) or a
        # timeout — either way, no verdict was produced.
        echo "CRASH"; return
    fi
    case "$line" in
        *"uncaught exception"*|*"panic"*|*"PANIC"*) echo "CRASH"; return ;;
    esac
    if [[ "$line" == Undefined* ]]; then
        echo "UB:$(sed -n 's/.*ub: "\([^"]*\)".*/\1/p' <<<"$line")"
    elif [[ "$line" == Defined* ]]; then
        echo "VAL:$(sed -n 's/.*value: "\([^"]*\)".*/\1/p' <<<"$line")"
    elif [[ "$line" == Error* ]]; then
        echo "ERR:$(sed -n 's/.*msg: "\([^"]*\)".*/\1/p' <<<"$line")"
    else
        # exit code disambiguates a bare/odd line
        [[ "$rc" -ge 2 ]] && echo "CRASH" || echo "OTHER:$line"
    fi
}

# Classify oracle-token vs lean-token into a lane status.
classify() {
    local o="$1" l="$2"
    if [[ "$o" == "$l" ]]; then echo "MATCH"
    elif [[ "$o" == "CRASH" ]]; then echo "ORACLE_CRASH"
    else echo "DIFF"; fi
}

: > "$OUTPUT_DIR/baseline.new"
declare -A CUR

run_c_case() {  # $1=name $2=cfile $3=libc(0/1)
    local name="$1" c="$2" libc="$3" orc=0 lrc=0
    local oflags=(--exec --batch)
    [[ "$libc" -eq 0 ]] && oflags+=(--nolibc)
    ( ulimit -v $ULIMIT_KB; exec timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" "${oflags[@]}" "$c" \
        > "$OUTPUT_DIR/$name.o" 2>/dev/null ) || orc=$?
    local oline; oline="$(head -1 "$OUTPUT_DIR/$name.o")"
    local otok; otok="$(verdict "$oline" "$orc")"
    # cabs-json (no --nolibc; the cpp side is identical between sides)
    ( ulimit -v $ULIMIT_KB; exec timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "$c" \
        > "$OUTPUT_DIR/$name.json" 2>/dev/null ) || fail "cabs-json failed for $name"
    [[ -s "$OUTPUT_DIR/$name.json" ]] || fail "empty cabs-json for $name"
    local largs=(--batch --first)
    [[ "$libc" -eq 1 ]] && largs+=("${LIBC_ARGS[@]}")
    ( ulimit -v $ULIMIT_KB; exec timeout "${TIMEOUT_SECS}s" \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" "${largs[@]}" \
        "$OUTPUT_DIR/$name.json" \
        > "$OUTPUT_DIR/$name.l" 2>"$OUTPUT_DIR/$name.lerr" ) || lrc=$?
    local lline; lline="$(head -1 "$OUTPUT_DIR/$name.l")"
    [[ -z "$lline" ]] && lline="$(head -1 "$OUTPUT_DIR/$name.lerr")"
    local ltok; ltok="$(verdict "$lline" "$lrc")"
    local status; status="$(classify "$otok" "$ltok")"
    CUR["$name"]="$status"
    printf "  %-14s %-20s  O[%s] L[%s]\n" "$status" "$name" "$otok" "$ltok"
    echo "$name $status" >> "$OUTPUT_DIR/baseline.new"
}

echo ""
echo "immaculate test-first lane (arc-14 S0)"
echo "======================================"

echo "[nolibc]"
for c in "$CORPUS"/nolibc/*.c; do
    run_c_case "$(basename "$c" .c)" "$c" 0
done

echo "[libc]"
libc_jsons_out=$("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$OUTPUT_DIR/libcjson") \
    || fail "libc_prep.sh --jsons failed (pin drift or oracle missing)"
mapfile -t LIBC_JSONS <<< "$libc_jsons_out"
[[ ${#LIBC_JSONS[@]} -eq 12 ]] || fail "expected 12 libc metadata jsons, got ${#LIBC_JSONS[@]}"
LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
for c in "$CORPUS"/libc/*.c; do
    run_c_case "$(basename "$c" .c)" "$c" 1
done

echo "[in-lean probe]"
# G6: CoreParser symbol-hash conflation. Run the probe under lake env lean
# from lean_frontend (root package; NOT a RelSem import — lake env lean is
# correct here). scripts/capped enforces the memory cap.
g6_out="$(cd "$PROJECT_ROOT/lean_frontend" && \
    "$PROJECT_ROOT/scripts/capped" lake env lean --run \
    "$CORPUS/g6-hash-collision.lean" 2>/dev/null | grep -v 'env:')"
g6_status="$(sed -n 's/^G6_STATUS=//p' <<<"$g6_out")"
[[ -n "$g6_status" ]] || fail "G6 probe produced no G6_STATUS line (output: $g6_out)"
CUR["g6-hash-collision"]="$g6_status"
printf "  %-14s %-20s\n" "$g6_status" "g6-hash-collision"
echo "g6-hash-collision $g6_status" >> "$OUTPUT_DIR/baseline.new"

echo ""
if $RECORD_BASELINE; then
    sort "$OUTPUT_DIR/baseline.new" -o "$OUTPUT_DIR/baseline.new"
    {
        echo "# arc-14 immaculate test-first lane baseline (scripts/test_immaculate.sh)."
        echo "#"
        echo "# THIS IS THE HONEST S0 BASELINE: most rows are EXPECTED-FAILING."
        echo "# DIFF / ORACLE_CRASH / CONFLATED are NOT gate failures — they are"
        echo "# the recorded current-tree wrong-answer state that the S1/S2 fixes"
        echo "# will FLIP. The lane is fail-closed against THIS file: a fix that"
        echo "# flips a row (or a regression on a MATCH row) exits nonzero and"
        echo "# forces a deliberate, justified re-record."
        echo "#"
        echo "# Status vocabulary:"
        echo "#   MATCH        oracle and Lean agree on the semantic verdict (control rows)."
        echo "#   DIFF         both sides produced a verdict; they disagree (the target bug)."
        echo "#   ORACLE_CRASH oracle fail-closed with an uncaught exception / assert;"
        echo "#                Lean silently returned a value (Lean-side latent-wrong)."
        echo "#   CONFLATED    G6 in-Lean probe: two distinct hash-colliding identifiers"
        echo "#                intern to the SAME symbol (silent conflation)."
        echo "#"
        echo "# Finding -> row map (registers: notes/2026-08-21_grumpy-audit-*.md):"
        echo "#   G1 semantics: g1-lt-null, g1-ge-funptr (relational kill-path -> value-path)"
        echo "#   G2 semantics: g2-memcpy-oob, g2-memcpy-readonly, g2-memcmp-uninit (checked-path bypass)"
        echo "#   G3 semantics: g3-realloc-non-heap (UB179c), g3-realloc-dead (UB179d) (wrong UB family)"
        echo "#   G4 semantics: g4-ffs-negative, g4-ffs-intmin (Int.toNat clamp); g4-ctz-nonzero is a control"
        echo "#   G5 semantics: g5-decode-question (ORACLE-WRONG: '\\?' is a legal C11 escape = 63,"
        echo "#                 gcc agrees; upstream failwiths -> upstream-filing candidate),"
        echo "#                 g5-decode-multichar (impl-defined; oracle fail-closed is defensible)"
        echo "#   G6 semantics: g6-hash-collision (CoreParser symbol-hash conflation)"
        echo "#"
        echo "# Expected post-fix shape (recorded so the flip is deliberate):"
        echo "#   G1/G2/G3 -> MATCH (Lean kills / emits the same UB as the oracle)."
        echo "#   G4       -> MATCH (Z/two's-complement semantics)."
        echo "#   G5 '\\?'  -> Lean C-correct (63) DIVERGES from the crashing oracle: expect a"
        echo "#               NEW status (Lean-right) + an upstream bug filing, NOT fix-to-match."
        echo "#   G5 'ab'  -> Lean fail-closed to agree with the oracle's rejection (still not MATCH-token;"
        echo "#               both fail-closed — re-record as the agreed-rejection shape)."
        echo "#   G6       -> off CONFLATED once the intern-time fail-stop tripwire lands."
        cat "$OUTPUT_DIR/baseline.new"
    } > "$BASELINE"
    echo "BASELINE RECORDED: $BASELINE"
    exit 0
fi

# --- fail-closed compare against the committed baseline ---
rc=0
declare -A BASE
while read -r name st; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    BASE["$name"]="$st"
done < "$BASELINE"

for name in "${!CUR[@]}"; do
    exp="${BASE[$name]:-<absent>}"
    got="${CUR[$name]}"
    if [[ "$exp" != "$got" ]]; then
        echo "DEVIATION: $name expected [$exp] got [$got]" >&2
        rc=1
    fi
done
for name in "${!BASE[@]}"; do
    [[ -z "${CUR[$name]:-}" ]] && { echo "MISSING: $name in baseline but not run" >&2; rc=1; }
done

if [[ $rc -eq 0 ]]; then
    echo "OK: lane matches committed baseline (DIFF/ORACLE_CRASH/CONFLATED rows are the EXPECTED S0 state)."
else
    echo "" >&2
    echo "A deviation means either a regression OR a fix flipped a row." >&2
    echo "If a fix legitimately flipped a row to MATCH, re-record deliberately:" >&2
    echo "  ./scripts/test_immaculate.sh --record-baseline   (in its own commit, with justification)" >&2
fi
exit $rc
