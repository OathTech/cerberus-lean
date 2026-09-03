/* IvMaxAlignment probe: is malloc(0)'s result 16-byte aligned?
   The concrete model allocates malloc regions at IvMaxAlignment
   (core_parser.mly:1536-1537 -> Ocaml_implementation max_alignment = 8 for
   DefaultImpl; lean_frontend/CoreParser.lean:1281-1282 hardcodes 16).
   Layout is deterministic: q then x are created (x 16-aligned), malloc's
   size_t argument temporary sits 8 below x, so an 8-aligned region lands
   at x-8 (not 16-aligned -> bit0 = 0) and a 16-aligned one at x-16
   (bit0 = 1); bit1 = x is 16-aligned (control). UB-free
   (implementation-defined pointer->integer conversion, C11 6.3.2.3p6).
   Expected: oracle 2, Lean 3 (the divergence). */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  void *q;
  _Alignas(16) int x = 1;
  q = malloc(0);
  if (q == NULL) return 255;
  return ((uintptr_t)q % 16 == 0) + 2 * ((uintptr_t)&x % 16 == 0);
}
