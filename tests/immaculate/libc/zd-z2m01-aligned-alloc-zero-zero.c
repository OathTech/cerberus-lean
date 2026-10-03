/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01 second witness; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero_zero.c. As zd-z2m01-aligned-alloc-zero.c with
   size 0 too. History: Lean's total `0 tmod 0 = 0` once passed the rem_t test and reached alloc(0, 0)
   (a DEFINED value, charter Z-13's clamp; then, after Z2, CerbMem.allocator's alignment-0 refusal — a
   both-crash of DIFFERENT causes). Since 2026-10-03 ([USER 2026-10-03] "we don't innovate wrt
   Cerberus-upstream ... fall back to loudly rejecting (either as unsupported, or matching upstream)")
   Lean's integerRem_t fail-stops on the zero divisor at std.core:385 exactly where the oracle's Z.rem
   raises Division_by_zero (impl_mem.ml:2481-2482): MATCH | L=CRASH is now the SAME cause on both
   engines (docs/2026-10-03_total-arith-and-bookkeeping-record.md).
   libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 0); return p != 0; }
