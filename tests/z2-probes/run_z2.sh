#!/bin/bash
# run_z2.sh — THREE-engine differential runner for the Z2 seam-audit probes
# (2026-09-03, branch audit/z2-seams). ADDITIVE, NON-GATING instrument,
# modelled on tests/noodle-probes/run_noodle.sh (noodle/semantics) with the
# un-forked upstream oracle added as engine (2). For each .c file runs
#   (1) fork oracle:      cerberus --exec --batch --mode=exhaustive [--nolibc]
#   (2) upstream oracle:  deps/cerberus-upstream main.exe, same flags
#   (3) Lean driver:      cerberus-lean --batch [--libc ...]  (cabs-json bridge)
# and prints every verdict line verbatim plus a one-line classification:
#   AGREE            fork == upstream == Lean on the verdict sequence
#   LEAN!=ORACLE     fork == upstream, Lean differs (Lean-side)
#   FORK!=UPSTREAM   the two oracles differ (fork drift / upstream bug)
#   *-NONE           an engine produced no verdict line (its exit code shown)
# Usage: run_z2.sh [--nolibc] [--timeout N] [--nolean] [--noupstream] f.c ...
# Needs env loaded (scripts/ce or scripts/env.sh) and, in libc mode, the 12
# libc metadata cabs-jsons at $Z2_LIBCJSON (default .tmp/z2/libcjson;
# produce with scripts/libc_prep.sh --jsons <dir>).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CERB="$ROOT/_build/default/backend/driver/main.exe"
RUNTIME="$ROOT/_build/install/default"
UP_ROOT="${Z2_UPSTREAM:-$ROOT/../../../deps/cerberus-upstream}"  # container root from worktrees/<repo>-<branch-dir>/
UP="$UP_ROOT/_build/default/backend/driver/main.exe"
UP_RUNTIME="$UP_ROOT/_build/install/default"
LEAN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
TIMEOUT_SECS=30
MODE=libc
RUN_LEAN=1
RUN_UP=1
FILES=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --nolibc) MODE=nolibc; shift ;;
        --timeout) TIMEOUT_SECS=$2; shift 2 ;;
        --nolean) RUN_LEAN=0; shift ;;
        --noupstream) RUN_UP=0; shift ;;
        *) FILES+=("$1"); shift ;;
    esac
done
for b in "$CERB" "$LEAN"; do [[ -x "$b" ]] || { echo "missing binary: $b" >&2; exit 2; }; done
[[ $RUN_UP -eq 1 && ! -x "$UP" ]] && { echo "missing upstream binary: $UP (pass --noupstream to skip)" >&2; exit 2; }
ORACLE_FLAGS=(--exec --batch --mode=exhaustive)
LEAN_ARGS=()
if [[ "$MODE" == nolibc ]]; then
    ORACLE_FLAGS=(--nolibc "${ORACLE_FLAGS[@]}")
else
    LIBCJSON="${Z2_LIBCJSON:-$ROOT/.tmp/z2/libcjson}"
    [[ -d "$LIBCJSON" ]] || { echo "libc jsons missing at $LIBCJSON (scripts/libc_prep.sh --jsons)" >&2; exit 2; }
    LEAN_ARGS=(--libc "$ROOT/tests/libc/libc.core")
    for j in "$LIBCJSON"/*.json; do LEAN_ARGS+=(--libc-tu "$j"); done
fi
CAPPED=(env "CERB_MEM_MAX=${CERB_TEST_MEM_MAX:-4G}" "$ROOT/scripts/capped")
mkdir -p "$ROOT/.tmp/z2"
seqof() { printf '%s\n' "$1" | grep -oE 'Undefined \{ub: "[^"]*"|Defined \{value: "[^"]*"|Error \{msg: "[^"]*"|Killed \{msg: "[^"]*"' ; return 0; }
filt() { grep -v '^Time spent' | grep -v 'cerberus-lean-proj env:'; }
for F in "${FILES[@]}"; do
    [[ -f "$F" ]] || { echo "no such file: $F" >&2; continue; }
    echo "##### $F ($MODE)"
    cerb_exit=0
    cerb_out=$( "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$CERB" --runtime="$RUNTIME" "${ORACLE_FLAGS[@]}" "$F" 2>&1 ) || cerb_exit=$?
    cerb_out=$(printf '%s\n' "$cerb_out" | filt)
    echo "--- FORK-ORACLE exit=$cerb_exit"; printf '%s\n' "$cerb_out" | head -20
    up_out=""; up_exit=0
    if [[ $RUN_UP -eq 1 ]]; then
        up_out=$( "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$UP" --runtime="$UP_RUNTIME" "${ORACLE_FLAGS[@]}" "$F" 2>&1 ) || up_exit=$?
        up_out=$(printf '%s\n' "$up_out" | filt)
        echo "--- UPSTREAM exit=$up_exit"; printf '%s\n' "$up_out" | head -20
    fi
    lean_out=""; lean_exit=0
    if [[ $RUN_LEAN -eq 1 ]]; then
        json=$(mktemp "$ROOT/.tmp/z2/z2.XXXXXX.json"); json_ok=true
        "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" "$CERB" --runtime="$RUNTIME" --cabs-json "$F" > "$json" 2>"$json.err" || json_ok=false
        if $json_ok; then
            lean_out=$( "${CAPPED[@]}" env LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" "$LEAN" --batch ${LEAN_ARGS[@]+"${LEAN_ARGS[@]}"} "$json" 2>&1 ) || lean_exit=$?
            lean_out=$(printf '%s\n' "$lean_out" | filt)
        else
            lean_out="(cabs-json failed: $(head -c 200 "$json.err" | tr '\n' ' '))"; lean_exit=98
        fi
        rm -f "$json" "$json.err"
        echo "--- LEAN exit=$lean_exit"; printf '%s\n' "$lean_out" | head -20
    fi
    cs=$(seqof "$cerb_out"); us=$(seqof "$up_out"); ls_=$(seqof "$lean_out")
    v=""
    if [[ -z "$cs" ]]; then v="FORK-NONE(exit=$cerb_exit)"; fi
    if [[ $RUN_UP -eq 1 && -z "$us" ]]; then v="$v UPSTREAM-NONE(exit=$up_exit)"; fi
    if [[ $RUN_LEAN -eq 1 && -z "$ls_" ]]; then v="$v LEAN-NONE(exit=$lean_exit)"; fi
    # full-line compare of every verdict line (stdout/stderr/loc fields are
    # verdict content under the rule): LINE-DIFF when the extracted tokens
    # agree but the full lines do not (e.g. the batchEscape finding)
    fl_c=$(printf '%s\n' "$cerb_out" | grep -E '^(Defined|Undefined|Error|Killed) \{' || true)
    fl_l=$(printf '%s\n' "$lean_out" | grep -E '^(Defined|Undefined|Error|Killed) \{' || true)
    if [[ -z "$v" ]]; then
        if [[ $RUN_UP -eq 1 && "$cs" != "$us" ]]; then v="FORK!=UPSTREAM"
        elif [[ $RUN_LEAN -eq 1 && "$cs" != "$ls_" ]]; then v="LEAN!=ORACLE"
        elif [[ $RUN_LEAN -eq 1 && "$fl_c" != "$fl_l" ]]; then v="AGREE-TOKENS LINE-DIFF (stdout/stderr/loc field bytes differ)"
        else v="AGREE"; fi
    fi
    echo "=== $(basename "$F"): $v"
done
