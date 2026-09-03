/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-76 (R2)).
   Origin: tests/noodle-probes/dynamic-addrs/da_offset.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (Specified(16) vs the oracle's Specified(8)); the fix
   commit re-records it MATCH (IvMaxAlignment = CerberusImpl.max_alignment, Z-76). The lane fails closed both ways. */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  void *q;
  _Alignas(16) int x = 1;
  q = malloc(0);
  if (q == NULL) return 255;
  return (int)((uintptr_t)&x - (uintptr_t)q);
}
