/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero.c. std.core:385 (aligned_alloc_proxy) evaluates
   `size rem_t align` with NO UB045 guard; with align 0 the oracle's op_ival IntRem_t = Z.rem
   (impl_mem.ml:11, :2481-2482) raises Division_by_zero (uncaught, exit 125) while Lean's
   integerRem_t was the total Int.tmod (x tmod 0 = x) and went on to a UB verdict. Pinned
   ORACLE_CRASH at the current Lean token; the Z2-M-01 fix (Lean fail-stops with the OCaml
   exception text, ruling Q4) re-records MATCH | L=CRASH. libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 8); return p != 0; }
