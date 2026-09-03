/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-08 (D7)).
   Origin: tests/noodle-probes/seam/seam_free_interior_pointer.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (Error MerrUndefinedFree Free_out_of_bound vs the oracle's UB179a); the fix
   commit re-records it MATCH (kill check order mirror, Z-08). The lane fails closed both ways. */
#include <stdlib.h>
int main(void) { char *p = malloc(8); free(p + 1); return 3; }
