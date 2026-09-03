/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-76 (R2)).
   Origin: tests/noodle-probes/dynamic-addrs/da_align16.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (Specified(3) vs the oracle's Specified(2)); the fix
   commit re-records it MATCH (IvMaxAlignment = CerberusImpl.max_alignment, Z-76). The lane fails closed both ways. */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  void *q;
  _Alignas(16) int x = 1;
  q = malloc(0);
  if (q == NULL) return 255;
  return ((uintptr_t)q % 16 == 0) + 2 * ((uintptr_t)&x % 16 == 0);
}
