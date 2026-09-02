#!/bin/bash
# test_immaculate.sh — arc-14 (the immaculate pass) targeted-differential
# lane (born TEST-FIRST at S0; wording refreshed post-S1 per D2).
#
# Targeted probes for the latent-wrong-answer GRAVE/SERIOUS items of the
# two grumpy-professor registers
# (notes/2026-08-21_grumpy-audit-cerberus-semantics.md and
#  .../grumpy-audit-lem-backend.md). These findings were latent precisely
# because the standing corpora never exercised the failing inputs; this
# lane exercises them permanently.
#
# THE BASELINE (tests/immaculate/baseline.txt) records the current
# EXPECTED state, re-recorded deliberately per fix batch with the flipped
# finding ids in the commit message. History: at S0 it recorded 12
# failing rows (the honest pre-fix state); after the S1 fix batches it
# records the post-fix shape — MATCH on the fixed rows, plus the
# documented-deliberate rows that are NOT MATCH by design:
#   g5-decode-question   ORACLE_CRASH, Lean pinned at 63 ('\?' is legal
#                        C11; the ORACLE is wrong — upstream-tray #10)
#   g5-escape-roundtrip  DIFF, Lean-right 127 vs oracle 87 (Char.escaped
#                        decimal read back as octal — upstream-tray #11)
#   g6-hash-collision    TRIPWIRE (parseFile fail-stops on constructed
#                        hash collisions)
# The script is fail-closed BOTH directions against that baseline: any
# deviation (regression or improvement) exits nonzero and forces a
# deliberate, justified re-record (the test_exec.sh / uri-baseline
# discipline).
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
# Per-test memory cap: `scripts/capped` at CERB_TEST_MEM_MAX (default 4G,
# cgroup RSS; common.sh CAPPED_TEST) — mem-scale S2 (2026-09-02, Q2 [USER
# 2026-09-02]) replacing the arc-5 `ulimit -v 4000000`. A cap breach (exit
# 137 + capped's OOM-KILLED witness) is token KILL on that side and lane
# status KILL — two KILL tokens never MATCH (classify below).

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
verdict() {   # <first-line> <rc> [<stderr-file>]
    local line="$1" rc="$2" errf="${3:-}"
    if is_cap_kill "$rc" "$errf"; then
        # memory-cap breach (exit 137 + capped's OOM-KILLED witness on
        # stderr): its own token, so it can never read as a verdict
        echo "KILL"; return
    fi
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
    if [[ "$o" == "KILL" || "$l" == "KILL" ]]; then echo "KILL"
    elif [[ "$o" == "$l" ]]; then echo "MATCH"
    elif [[ "$o" == "CRASH" ]]; then echo "ORACLE_CRASH"
    else echo "DIFF"; fi
}

: > "$OUTPUT_DIR/baseline.new"
declare -A CUR

run_c_case() {  # $1=name $2=cfile $3=libc(0/1) [$4=--args string]
    local name="$1" c="$2" libc="$3" xargs="${4:-}" orc=0 lrc=0
    local oflags=(--exec --batch)
    [[ "$libc" -eq 0 ]] && oflags+=(--nolibc)
    # argv rows (2026-09-01 S-basket item 7): the same --args string goes
    # to both sides (oracle backend/driver/main.ml:512-514; Lean driver
    # Main.lean --args). Empty string = no flag (the historical argv).
    [[ -n "$xargs" ]] && oflags+=(--args "$xargs")
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" "${oflags[@]}" "$c" \
        > "$OUTPUT_DIR/$name.o" 2>"$OUTPUT_DIR/$name.oerr" ) || orc=$?
    local oline; oline="$(head -1 "$OUTPUT_DIR/$name.o")"
    local otok; otok="$(verdict "$oline" "$orc" "$OUTPUT_DIR/$name.oerr")"
    # cabs-json (no --nolibc; the cpp side is identical between sides)
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --runtime="$RUNTIME_DIR" --cabs-json "$c" \
        > "$OUTPUT_DIR/$name.json" 2>/dev/null ) || fail "cabs-json failed for $name"
    [[ -s "$OUTPUT_DIR/$name.json" ]] || fail "empty cabs-json for $name"
    local largs=(--batch --first)
    [[ -n "$xargs" ]] && largs+=(--args "$xargs")
    [[ "$libc" -eq 1 ]] && largs+=("${LIBC_ARGS[@]}")
    ( "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" \
        env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" "${largs[@]}" \
        "$OUTPUT_DIR/$name.json" \
        > "$OUTPUT_DIR/$name.l" 2>"$OUTPUT_DIR/$name.lerr" ) || lrc=$?
    local lline; lline="$(head -1 "$OUTPUT_DIR/$name.l")"
    [[ -z "$lline" ]] && lline="$(head -1 "$OUTPUT_DIR/$name.lerr")"
    local ltok; ltok="$(verdict "$lline" "$lrc" "$OUTPUT_DIR/$name.lerr")"
    local status; status="$(classify "$otok" "$ltok")"
    # The Lean token is PART of the recorded state (F2 lane hardening):
    # on ORACLE_CRASH rows the status alone cannot see a Lean-side value
    # change (e.g. the '\?' fix moving 0 -> 63), so the baseline pins
    # status AND Lean token.
    CUR["$name"]="$status | L=$ltok"
    printf "  %-14s %-20s  O[%s] L[%s]\n" "$status" "$name" "$otok" "$ltok"
    echo "$name $status | L=$ltok" >> "$OUTPUT_DIR/baseline.new"
}

echo ""
echo "immaculate test-first lane (arc-14 S0)"
echo "======================================"

echo "[nolibc]"
for c in "$CORPUS"/nolibc/*.c; do
    run_c_case "$(basename "$c" .c)" "$c" 0
done

echo "[argv]"
# --args differential rows (2026-09-01 S-basket item 7; probe set =
# arc-15 S0 preliminaries probe (b), values hand-checked there). Each
# row runs BOTH sides with --args "ab cd" — argv becomes
# ["cmdname","ab","cd"], exercising prepare_main_args' argv object
# initialization (generated/Driver.lean) through the CLI.
for c in "$CORPUS"/argv/*.c; do
    run_c_case "$(basename "$c" .c)-args" "$c" 0 "ab cd"
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
# from lean_frontend (root package; the probe imports only root-package
# modules, so lake env lean is correct here — no cross-package prefix).
# scripts/capped enforces the memory cap.
g6_out="$(cd "$PROJECT_ROOT/lean_frontend" && \
    "$PROJECT_ROOT/scripts/capped" lake env lean --run \
    "$CORPUS/g6-hash-collision.lean" 2>/dev/null | grep -v 'env:')"
g6_status="$(sed -n 's/^G6_STATUS=//p' <<<"$g6_out")"
[[ -n "$g6_status" ]] || fail "G6 probe produced no G6_STATUS line (output: $g6_out)"
CUR["g6-hash-collision"]="$g6_status"
printf "  %-14s %-20s\n" "$g6_status" "g6-hash-collision"
echo "g6-hash-collision $g6_status" >> "$OUTPUT_DIR/baseline.new"

# Ill-typed-store kill (2026-09-01 S-basket item 5): CerbMem.storeM's
# internal-invariant guard (impl_mem.ml:1673-1681 mirror) is
# unreachable from typed C through either pipeline, so its pin is an
# in-Lean probe (probe header has the reachability argument); expected
# status KILL.
it_out="$(cd "$PROJECT_ROOT/lean_frontend" && \
    "$PROJECT_ROOT/scripts/capped" lake env lean --run \
    "$CORPUS/illtyped-store.lean" 2>/dev/null | grep -v 'env:')"
it_status="$(sed -n 's/^ILLTYPED_STATUS=//p' <<<"$it_out")"
[[ -n "$it_status" ]] || fail "illtyped-store probe produced no ILLTYPED_STATUS line (output: $it_out)"
CUR["illtyped-store"]="$it_status"
printf "  %-14s %-20s\n" "$it_status" "illtyped-store"
echo "illtyped-store $it_status" >> "$OUTPUT_DIR/baseline.new"

echo ""
if $RECORD_BASELINE; then
    sort "$OUTPUT_DIR/baseline.new" -o "$OUTPUT_DIR/baseline.new"
    {
        echo "# arc-14 immaculate test-first lane baseline (scripts/test_immaculate.sh)."
        echo "#"
        echo "# THIS IS THE HONEST CURRENT-TREE BASELINE (recorded at S0; re-recorded"
        echo "# per fix batch with the flipped finding ids in the commit message)."
        echo "# DIFF / ORACLE_CRASH / CONFLATED rows are NOT gate failures — they are"
        echo "# the recorded wrong-answer state the remaining S1/S2 fixes will FLIP."
        echo "# The lane is fail-closed against THIS file: a fix that flips a row"
        echo "# (or a regression on a MATCH row) exits nonzero and forces a"
        echo "# deliberate, justified re-record."
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
        echo "#   G4 semantics: g4-ffs-negative, g4-ffs-intmin (Int.toNat clamp); g4-ctz-nonzero"
        echo "#                 and g4-bswap-controls are controls (16/32 asserts unreachable from C;"
        echo "#                 bswap64 >= 2^63 IS reachable: g4-bswap64-overflow, both fail-stop, tray #12)"
        echo "#   S12 semantics: g5-escape-roundtrip (ORACLE-WRONG: Char.escaped decimal read back"
        echo "#                 as octal corrupts %c-stored char 127 -> 87; gcc & Lean = 127)"
        echo "#   G5 semantics: g5-decode-question (ORACLE-WRONG: '\\?' is a legal C11 escape = 63,"
        echo "#                 gcc agrees; upstream failwiths -> upstream-filing candidate),"
        echo "#                 g5-decode-multichar (impl-defined; oracle fail-closed is defensible)"
        echo "#   G6 semantics: g6-hash-collision (CoreParser symbol-hash conflation)"
        echo "#"
        echo "# Post-S1 state (the S0 flips are DONE — see the F1-F3 commit messages):"
        echo "#   G1/G2/G3/G4 rows and 'ab' -> MATCH (fixed in S1 F1/F2)."
        echo "#   g5-decode-question -> ORACLE_CRASH with L pinned Specified(63):"
        echo "#     '\\?' is legal C11 (= 63, gcc agrees); the ORACLE failwiths — oracle-wrong,"
        echo "#     upstream-tray #10. Never fix-to-match."
        echo "#   g5-escape-roundtrip -> DIFF, Lean-right (127 vs oracle 87): Char.escaped"
        echo "#     decimal read back through the octal decoder corrupts the printf %c"
        echo "#     round-trip upstream — oracle-wrong, upstream-tray #11. Never fix-to-match."
        echo "#   g6-hash-collision -> TRIPWIRE (CoreParser fail-stops on hash collisions, F3)."
        cat "$OUTPUT_DIR/baseline.new"
    } > "$BASELINE"
    echo "BASELINE RECORDED: $BASELINE"
    exit 0
fi

# --- fail-closed compare against the committed baseline ---
rc=0
declare -A BASE
while read -r name rest; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    BASE["$name"]="$rest"
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
    echo "OK: lane matches the committed post-S1 baseline (mostly MATCH; the intended non-MATCH rows: g5-decode-question ORACLE_CRASH/L=63 and g5-escape-roundtrip DIFF/L=127 are oracle-wrong — upstream-tray #10/#11 — and g6 is TRIPWIRE)."
else
    echo "" >&2
    echo "A deviation means either a regression OR a fix flipped a row." >&2
    echo "If a fix legitimately flipped a row to MATCH, re-record deliberately:" >&2
    echo "  ./scripts/test_immaculate.sh --record-baseline   (in its own commit, with justification)" >&2
fi
exit $rc
