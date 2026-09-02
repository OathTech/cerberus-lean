#!/bin/bash
# gen_probes.sh — synthesize the MEMORY-SCALE probe corpus (arc/mem-scale,
# 2026-09-01) into tests/mem-scale-probes/probes/. Deterministic; the
# generated files are committed so the corpus is inspectable; re-running
# must reproduce them byte-identically.
#
# Classes (charter task 2):
#   a_uninit_local_N  : char a[N] local, uninitialised, touch last element
#                       (allocateObject initOpt=none path: List.replicate)
#   a_zero_global_N   : char g[N] at file scope (static zero-init: allocate
#                       WITH an initial value -> memValueToBytes of an
#                       N-element MVarray, then per-byte map insert)
#   b_zero_local_N    : char a[N] = {0} local (zero-init through the store
#                       path: memValueToBytes + writeBytesTo)
#   c_struct_arg_N    : struct of N bytes passed BY VALUE twice (load of the
#                       whole aggregate = readBytesFrom + reconstructValue;
#                       then a store into the parameter object)
#   c_struct_ret_N    : struct of N bytes RETURNED by value once
#   d_loop_N          : loop storing N bytes one at a time (interpreter
#                       step cost + per-byte store path)
#   e_memcpy_N        : memset then memcpy of N bytes (libc mode only)
#   z_base            : empty main (fixed-cost baseline)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/probes"
mkdir -p "$OUT"
rm -f "$OUT"/*.c

emit() { printf '%s\n' "$2" > "$OUT/$1.c"; }

emit z_base 'int main(void) { return 7; }'

for N in 1000 10000 100000 1000000 10000000; do
  emit "a_uninit_local_$N" "int main(void) {
  char a[$N];
  a[$N - 1] = 7;
  return a[$N - 1];
}"
  emit "a_zero_global_$N" "char g[$N];
int main(void) {
  g[$N - 1] = 7;
  return g[$N - 1] + g[0];
}"
  emit "b_zero_local_$N" "int main(void) {
  char a[$N] = {0};
  a[$N - 1] = 7;
  return a[$N - 1] + a[0];
}"
done

for N in 1024 4096 16384 65536 262144; do
  emit "c_struct_arg_$N" "struct big { char b[$N]; };
struct big gb;
int foo(struct big s, int x) { return s.b[x]; }
int main(void) { return foo(gb, 0) + foo(gb, $N - 1); }"
  emit "c_struct_ret_$N" "struct big { char b[$N]; };
struct big gb;
struct big mk(void) { struct big s = gb; s.b[$N - 1] = 7; return s; }
int main(void) { struct big r = mk(); return r.b[$N - 1]; }"
done

for N in 1000 10000 100000 1000000; do
  emit "d_loop_$N" "int main(void) {
  char a[$N];
  int i;
  for (i = 0; i < $N; i++) a[i] = (char)i;
  return a[$N - 1];
}"
  emit "e_memcpy_$N" "#include <string.h>
char a[$N], b[$N];
int main(void) {
  memset(a, 7, $N);
  memcpy(b, a, $N);
  return b[$N - 1];
}"
done
ls "$OUT" | wc -l
