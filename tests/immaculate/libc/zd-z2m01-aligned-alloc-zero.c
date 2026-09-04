/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero.c. std.core:385 (aligned_alloc_proxy) evaluates
   `size rem_t align` with NO UB045 guard; with align 0 the oracle's op_ival IntRem_t = Z.rem
   (impl_mem.ml:11, :2481-2482) raises Division_by_zero (uncaught, exit 125) while Lean's
   integerRem_t is the total Int.tmod (x tmod 0 = x) and goes on to `Undefined {ub: "DUMMY(align_alloc)", …}`.
   RE-CLASSIFIED [USER 2026-09-03] (docs/2026-09-03_logical-semantics-referent-ruling.md): the oracle's
   Division_by_zero is a KIND-2 OCaml-execution artifact (a missing guard) — NOT mirrored; the logical
   meaning of a Core `rem_t` by zero at std.core:385 is an OPERATOR DECISION (record §10). Pinned
   ORACLE_CRASH | L=UB:DUMMY(align_alloc) so the pending row stays visible; flips when the decision lands
   (Lean side) or upstream guards std.core:385 (oracle side; tray). libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 8); return p != 0; }
