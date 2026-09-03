#!/bin/bash
# run_noodle.sh — three-engine differential runner for the noodle probe
# corpus (2026-09-03, branch noodle/semantics). ADDITIVE, NON-GATING
# instrument. For each .c file runs
#   (1) the OCaml oracle:  cerberus --exec --batch --mode=exhaustive
#   (2) the Lean driver:   cerberus-lean --batch  (via the cabs-json bridge)
#   (3) native gcc -O0 -w  (exit status + stdout), when GCC=1 (default)
# and prints each engine's verdict lines verbatim plus a one-line
# classification:
#   AGREE            oracle == Lean on the full verdict sequence
#                    (+ stdout in libc mode)
#   LEAN!=ORACLE     the headline class — both produced verdicts, differ
#   LEAN-NONE / ORACLE-NONE / BOTH-NONE  one/both engines produced no verdict
# The gcc column is informational (gcc exit byte + stdout); the reader
# compares it against the Specified(n) payload by hand (gcc exit is n mod 256).
# Invocations mirror tests/parity-probes/run_probe.sh (same flags, same
# per-test memory cap via scripts/capped, CERB_TEST_MEM_MAX default 4G).
#
# Usage: run_noodle.sh [--nolibc] [--timeout N] [--nogcc] file.c [file.c ...]
# Needs env loaded (scripts/ce) and libc jsons at $PD_LIBCJSON
# (default .tmp/pd/libcjson; scripts/libc_prep.sh --jsons <dir>).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CERB="$ROOT/_build/default/backend/driver/main.exe"
LEAN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
RUNTIME="$ROOT/_build/install/default"
TIMEOUT_SECS=30
MODE=libc
GCC=1
FILES=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --nolibc) MODE=nolibc; shift ;;
        --timeout) TIMEOUT_SECS=$2; shift 2 ;;
        --nogcc) GCC=0; shift ;;
        *) FILES+=("$1"); shift ;;
    esac
done
ORACLE_FLAGS=(--exec --batch --mode=exhaustive)
LEAN_ARGS=()
if [[ "$MODE" == nolibc ]]; then
    ORACLE_FLAGS=(--nolibc "${ORACLE_FLAGS[@]}")
else
    LIBCJSON="${PD_LIBCJSON:-$ROOT/.tmp/pd/libcjson}"
    LEAN_ARGS=(--libc "$ROOT/tests/libc/libc.core")
    for j in "$LIBCJSON"/*.json; do LEAN_ARGS+=(--libc-tu "$j"); done
fi
CAPPED=(env "CERB_MEM_MAX=${CERB_TEST_MEM_MAX:-4G}" "$ROOT/scripts/capped")
mkdir -p "$ROOT/.tmp/pd"
# whole Undefined line (ub, stderr, loc) since the zero-discrepancy arc (charter §4.1)
seqof() { printf '%s\n' "$1" | grep -oE '^Undefined \{.*\}$|^Defined \{value: "[^"]*"|^Error \{msg: "[^"]*"|^Killed \{msg: "[^"]*"' ; return 0; }
for F in "${FILES[@]}"; do
    [[ -f "$F" ]] || { echo "no such file: $F" >&2; continue; }
    echo "##### $F ($MODE)"
    cerb_exit=0
    cerb_out=$( "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$CERB" --runtime="$RUNTIME" "${ORACLE_FLAGS[@]}" "$F" 2>&1 ) || cerb_exit=$?
    cerb_out=$(printf '%s\n' "$cerb_out" | grep -v '^Time spent' | grep -v 'cerberus-lean-proj env:')
    echo "--- ORACLE exit=$cerb_exit"
    printf '%s\n' "$cerb_out" | head -20
    json=$(mktemp "$ROOT/.tmp/pd/noodle.XXXXXX.json")
    json_ok=true
    "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$CERB" --runtime="$RUNTIME" --cabs-json "$F" > "$json" 2>"$json.err" || json_ok=false
    lean_exit=0
    if $json_ok; then
        lean_out=$( "${CAPPED[@]}" env LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" "$LEAN" --batch ${LEAN_ARGS[@]+"${LEAN_ARGS[@]}"} "$json" 2>&1 ) || lean_exit=$?
        lean_out=$(printf '%s\n' "$lean_out" | grep -v 'cerberus-lean-proj env:')
    else
        lean_out="(cabs-json failed: $(head -c 200 "$json.err" | tr '\n' ' '))"; lean_exit=98
    fi
    rm -f "$json" "$json.err"
    echo "--- LEAN exit=$lean_exit"
    printf '%s\n' "$lean_out" | head -20
    if [[ $GCC -eq 1 ]]; then
        bin=$(mktemp "$ROOT/.tmp/pd/noodle.XXXXXX.bin")
        if gcc -O0 -w -o "$bin" "$F" 2>"$bin.err"; then
            g_out=$(timeout 10s "$bin" 2>&1); g_exit=$?
            echo "--- GCC exit=$g_exit stdout=$(printf '%s' "$g_out" | head -c 300 | sed 's/$/\\n/' | tr -d '\n')"
        else
            echo "--- GCC compile-failed: $(head -1 "$bin.err")"
        fi
        rm -f "$bin" "$bin.err"
    fi
    cs=$(seqof "$cerb_out"); ls_=$(seqof "$lean_out")
    dc=$(printf '%s\n' "$cerb_out" | grep -E '^Defined \{' || true)
    dl=$(printf '%s\n' "$lean_out" | grep -E '^Defined \{' || true)
    if [[ -z "$cs" && -z "$ls_" ]]; then v="BOTH-NONE (oracle exit=$cerb_exit lean exit=$lean_exit)"
    elif [[ -z "$cs" ]]; then v="ORACLE-NONE (oracle exit=$cerb_exit)"
    elif [[ -z "$ls_" ]]; then v="LEAN-NONE (lean exit=$lean_exit)"
    elif [[ "$cs" != "$ls_" ]]; then v="LEAN!=ORACLE"
    elif [[ "$MODE" == libc && "$dc" != "$dl" ]]; then v="STDOUT-DIFF"
    else v="AGREE"; fi
    echo "=== $(basename "$F"): $v"
done
