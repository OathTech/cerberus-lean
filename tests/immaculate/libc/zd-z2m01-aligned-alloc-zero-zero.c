/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01 second witness; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero_zero.c. As zd-z2m01-aligned-alloc-zero.c with
   size 0 too: Lean's `0 tmod 0 = 0` PASSED the rem_t test and reached alloc(0, 0), where
   allocateRegion clamped align to 1 (charter Z-13) and returned a DEFINED value where the oracle
   crashes (Division_by_zero at std.core:385) — the worst class. Pinned ORACLE_CRASH at the current
   Lean token; the Z2-M-01 fix re-records MATCH | L=CRASH. libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 0); return p != 0; }
