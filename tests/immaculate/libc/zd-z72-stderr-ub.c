/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-72 (R1 F1)).
   Origin: the charter's R1 probe se1.c (stderr accumulated in the killed state) (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (Undefined line with stderr "" vs the oracle's stderr "E1"); the fix
   commit re-records it MATCH (killed-state stderr rendered, Z-72). The lane fails closed both ways. */
#include <stdio.h>
int main(void) { fprintf(stderr, "E1"); int *p = 0; return *p; }
