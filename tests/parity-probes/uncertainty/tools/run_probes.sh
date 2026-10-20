#!/bin/bash
# run_probes.sh — run every probe of a directory on gcc and on both engines.
# usage (from anywhere): tests/parity-probes/uncertainty/tools/run_probes.sh <dir> <out.txt> [glob]
# Per probe one line:  <name>.c | gcc=<exit code = return value mod 256, or COMPILE_FAIL(...)> | <the harness's
# "[1/1] ..." line, verbatim>.  The harness is the repository's scripts/test_exec.sh (oracle --nolibc exhaustive
# batch vs the Lean port on the oracle's --cabs-json), run with SKIP_BUILD=1; set CERB_ENV_WRAPPER to a command
# that provides the OCaml/opam environment if your shell does not (on the Oath boxes: the container's scripts/ce).
set -u
D=$1; OUT=$2; G=${3:-*.c}
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
D="$(cd "$D" && pwd)"
cd "$ROOT"
: > "$OUT"
for f in "$D"/$G; do
  b=$(basename "$f"); exe="$D/${b%.c}.gcc"
  if gcc -std=c11 -w -o "$exe" "$f" 2>"$exe.err"; then
    "$exe"; rc=$?; gccres="gcc=$rc"
  else
    gccres="gcc=COMPILE_FAIL($(head -c 200 "$exe.err" | tr '\n' ' '))"
  fi
  rm -f "$exe" "$exe.err"
  line=$(SKIP_BUILD=1 ${CERB_ENV_WRAPPER:-} ./scripts/test_exec.sh "$f" 2>&1 | grep -E '^\[1/1\]' | head -1 | cut -c1-400)
  printf '%s | %s | %s\n' "$b" "$gccres" "$line" | tee -a "$OUT"
done
