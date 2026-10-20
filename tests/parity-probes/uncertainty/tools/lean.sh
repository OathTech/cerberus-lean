#!/bin/bash
# lean.sh — the Lean port's --batch verdict (or panic text) for one probe: the oracle binary exports the Cabs
# JSON, then the port runs it exhaustively; the JSON goes to .tmp/uncertainty-probes/ under the repository root.
# usage: tests/parity-probes/uncertainty/tools/lean.sh <file.c>   (CERB_ENV_WRAPPER as in run_probes.sh)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"; f="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
cd "$ROOT"; mkdir -p .tmp/uncertainty-probes; j=".tmp/uncertainty-probes/$(basename "${f%.c}").json"
${CERB_ENV_WRAPPER:-} _build/default/backend/driver/main.exe --runtime="$PWD/_build/install/default" --cabs-json "$f" > "$j" 2>"$j.err" || { echo "[cabs-json export failed: $(head -c 300 "$j.err")]"; exit 0; }
LEAN_ABORT_ON_PANIC=1 scripts/capped lean_frontend/.lake/build/bin/cerberus-lean --batch --runtime="$PWD/_build/install/default" "$j" 2>&1 | head -c 1500; echo " [lean exit ${PIPESTATUS[0]}]"
