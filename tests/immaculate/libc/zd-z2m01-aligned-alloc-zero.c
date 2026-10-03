/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero.c. std.core:385 (aligned_alloc_proxy) evaluates
   `size rem_t align` with NO UB045 guard; with align 0 the oracle's op_ival IntRem_t = Z.rem
   (impl_mem.ml:11, :2481-2482) raises Division_by_zero (uncaught, exit 125). Until 2026-10-03 Lean's
   integerRem_t was the total Int.tmod (x tmod 0 = x) and went on to `Undefined {ub: "DUMMY(align_alloc)", …}`,
   a value upstream never chooses (pinned ORACLE_CRASH under the since-superseded 2026-09-03 KIND-2 reading).
   MIRRORED 2026-10-03 under [USER 2026-10-03] ("we don't innovate wrt Cerberus-upstream ... fall back to
   loudly rejecting (either as unsupported, or matching upstream)"): integerRem_t fail-stops on a zero
   divisor -> both-crash MATCH | L=CRASH. Z2 record §10.1's recommendation is WITHDRAWN (addendum there;
   docs/2026-10-03_total-arith-and-bookkeeping-record.md). libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 8); return p != 0; }
