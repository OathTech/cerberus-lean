#!/usr/bin/env bash
# build.sh <lean-toolchain-dir> <out-dir>
# Compiles every .lean file next to this script to a standalone executable.
# Recipe: lean -c F.c F.lean ; leanc -O3 -o F F.c   (static link against the
# toolchain's libInit/libleanrt; no lake, no dependencies).
set -euo pipefail
TC="$1"; OUT="$2"
SRC="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$OUT"
for f in "$SRC"/*.lean; do
  b="$(basename "$f" .lean)"
  cp "$f" "$OUT/$b.lean"
  ( cd "$OUT" && "$TC/bin/lean" -c "$b.c" "$b.lean" && "$TC/bin/leanc" ${LEANC_FLAGS:--O3} -o "$b" "$b.c" )
  echo "built $OUT/$b with $("$TC/bin/lean" --version)"
done
