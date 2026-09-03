/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-05 (D4)).
   Origin: tests/noodle-probes/seam/seam_copy_alloc_id.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (Specified(1) vs the oracle's Specified(2)); the fix
   commit re-records it MATCH (copy_alloc_id mirror, Z-05). The lane fails closed both ways. */
#include <stdint.h>
int main(void) { int x = 1, y = 2; int *p = __cerbvar_copy_alloc_id((uintptr_t)&y, &x); return *p; }
