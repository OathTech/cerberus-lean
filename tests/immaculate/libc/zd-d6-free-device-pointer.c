/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-07 (D6)).
   Origin: tests/noodle-probes/seam/seam_free_device_pointer.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (UB179a vs the oracle's Specified(3)); the fix
   commit re-records it MATCH (kill arms mirror, Z-07). The lane fails closed both ways. */
#include <stdlib.h>
int main(void) { int *p = (int*)0xABC; free(p); return 3; }
