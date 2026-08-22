// B' (arc-14 S4b re-grade record item): memcmp with a huge size_t.
// Reading past the object is UB, so ANY verdict-with-UB or clean kill
// is defensible — but the ORACLE dies on an uncaught Z.Overflow
// (impl_mem.ml memcmp does `Z.to_int size_n`, which raises for
// size >= 2^62-ish) — a tool crash, not a UB verdict: upstream-tray
// #13. The Lean side's checked per-byte loop kills cleanly at the
// first out-of-bounds byte (UB_CERB002a out-of-bound load).
// EXPECTED lane row: ORACLE_CRASH with the Lean token pinned.
#include <string.h>
int main(void) {
  char a[4] = {1,2,3,4};
  char b[4] = {1,2,3,4};
  return memcmp(a, b, (size_t)-1);
}
