#!/bin/bash
# run_probe.sh — single-file differential runner for the parity-detective
# probe lane (2026-08-30, probe/parity-detective). ADDITIVE instrument:
# runs ONE .c file through oracle (exhaustive batch) and the Lean exec
# driver (cabs-json bridge) and prints both outputs plus an agreement
# verdict. Complete verdicts/statuses use the shared byte observation codec;
# NON-GATING, no baseline.
#
# Usage: run_probe.sh [--nolibc] [--timeout N] file.c
#   Default mode is libc (like the sweep's torture/tcc/suite lanes).
#   Needs env loaded (scripts/ce) and libc jsons prepped at
#   $PD_LIBCJSON (default .tmp/pd/libcjson relative to repo root).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$ROOT/scripts/observations.sh"
CERB="$ROOT/_build/default/backend/driver/main.exe"
LEAN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
RUNTIME="$ROOT/_build/install/default"
TIMEOUT_SECS=15
MODE=libc
while [[ $# -gt 1 ]]; do
    case $1 in
        --nolibc) MODE=nolibc; shift ;;
        --timeout) TIMEOUT_SECS=$2; shift 2 ;;
        *) echo "unknown option $1" >&2; exit 2 ;;
    esac
done
F="$1"
[[ -f "$F" ]] || { echo "no such file: $F" >&2; exit 2; }
"$ROOT/tools/check_driver_fresh.sh" --check || exit 2
mkdir -p "$ROOT/.tmp/pd/observations" || exit 2
EVIDENCE=$(mktemp -d "$ROOT/.tmp/pd/observations/probe.XXXXXXXX") || exit 2
echo "Raw observations: $EVIDENCE"

ORACLE_FLAGS=(--exec --batch --mode=exhaustive)
LEAN_ARGS=()
if [[ "$MODE" == nolibc ]]; then
    ORACLE_FLAGS=(--nolibc "${ORACLE_FLAGS[@]}")
else
    LIBCJSON="${PD_LIBCJSON:-$ROOT/.tmp/pd/libcjson}"
    LEAN_ARGS=(--libc "$ROOT/tests/libc/libc.core")
    for j in "$LIBCJSON"/*.json; do LEAN_ARGS+=(--libc-tu "$j"); done
fi

# Per-test memory cap: `scripts/capped` at CERB_TEST_MEM_MAX (default 4G,
# cgroup RSS) — mem-scale S2 (2026-09-02, Q2 [USER 2026-09-02]) replacing
# the arc-5 `ulimit -v 4000000`; a cap breach (exit 137 + capped's
# OOM-KILLED witness in the captured output) is reported as OOM-KILLED,
# never as a verdict.
CAPPED=(env "CERB_MEM_MAX=${CERB_TEST_MEM_MAX:-4G}" "$ROOT/scripts/capped")
kill_note() { [[ "$1" -eq 137 && "$2" == *"capped: OOM-KILLED"* ]] && echo " OOM-KILLED (exit 137 — memory cap ${CERB_TEST_MEM_MAX:-4G} breached)"; return 0; }
cerb_exit=0
cerb_out=$(observation_capture "$EVIDENCE/oracle" "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" \
    "$CERB" --runtime="$RUNTIME" "${ORACLE_FLAGS[@]}" "$F") || cerb_exit=$?
echo "=== ORACLE (exit $cerb_exit)$(kill_note $cerb_exit "$cerb_out") ==="
printf '%s\n' "$cerb_out" | grep -v '^Time spent'

mkdir -p "$ROOT/.tmp/pd" || { echo "run_probe.sh: cannot create $ROOT/.tmp/pd" >&2; exit 2; }
json="$EVIDENCE/bridge.stdout"
json_ok=true
observation_capture "$EVIDENCE/bridge" "${CAPPED[@]}" timeout "${TIMEOUT_SECS}s" \
    "$CERB" --runtime="$RUNTIME" --cabs-json "$F" > "$EVIDENCE/bridge.display" || json_ok=false
[[ -s "$json" ]] || json_ok=false

lean_exit=0
if $json_ok; then
    lean_out=$(observation_capture "$EVIDENCE/lean" "${CAPPED[@]}" env LEAN_ABORT_ON_PANIC=1 timeout "${TIMEOUT_SECS}s" \
        "$LEAN" --batch ${LEAN_ARGS[@]+"${LEAN_ARGS[@]}"} "$json") || lean_exit=$?
else
    lean_out="(cabs-json failed)"; lean_exit=98
fi
echo "=== LEAN (exit $lean_exit)$(kill_note $lean_exit "$lean_out") ==="
printf '%s\n' "$lean_out"

cs=$(observation_tokens "$EVIDENCE/oracle") || cs=""
ls_=$(observation_tokens "$EVIDENCE/lean") || ls_=""
echo "=== VERDICT ==="
if [[ -z "$cs" && -z "$ls_" ]]; then echo "BOTH-NO-VERDICT (oracle exit=$cerb_exit lean exit=$lean_exit)"
elif [[ -z "$cs" ]]; then echo "ORACLE-NO-VERDICT lean=$(printf '%s' "$ls_" | tr '\n' '|')"
elif [[ -z "$ls_" ]]; then echo "PARITY-GAP: oracle-has-verdict, lean-none (lean exit=$lean_exit)"
elif [[ "$cs" != "$ls_" ]]; then echo "PARITY-GAP: full observations differ Lean=$(printf '%s' "$ls_" | tr '\n' '|') Cerberus=$(printf '%s' "$cs" | tr '\n' '|')"
else echo "AGREE $(printf '%s' "$cs" | tr '\n' '|')"
fi
