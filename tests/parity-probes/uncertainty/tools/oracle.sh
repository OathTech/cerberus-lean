#!/bin/bash
# oracle.sh — the oracle's own --batch verdict (or crash text) for one probe, plus its exit code.
# usage: tests/parity-probes/uncertainty/tools/oracle.sh <file.c>   (CERB_ENV_WRAPPER as in run_probes.sh)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"; f="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
cd "$ROOT"
${CERB_ENV_WRAPPER:-} _build/default/backend/driver/main.exe --runtime="$PWD/_build/install/default" --nolibc --exec --mode=exhaustive --batch "$f" 2>&1 | head -c 1500; echo " [oracle exit ${PIPESTATUS[0]}]"
