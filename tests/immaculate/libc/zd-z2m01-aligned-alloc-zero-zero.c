/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01 second witness; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero_zero.c. As zd-z2m01-aligned-alloc-zero.c with
   size 0 too: Lean's `0 tmod 0 = 0` PASSED the rem_t test and reached alloc(0, 0), where
   allocateRegion clamped align to 1 (charter Z-13) and returned a DEFINED value where the oracle
   crashes (Division_by_zero at std.core:385) — the worst class. RE-CLASSIFIED [USER 2026-09-03] (the
   logical-semantics referent ruling): the oracle's crash is a KIND-2 artifact, not mirrored; after Z2 the
   total `rem_t` still passes and `alloc(0, 0)` reaches CerbMem.allocator, whose alignment-0 arm is a loud
   PENDING-DECISION refusal (impl_mem.ml:1252 `quomod` raises there — also kind 2; the `.max 1` clamp was
   fail-open) — so both engines crash, for DIFFERENT reasons: MATCH | L=CRASH is a coincidence of failure
   class, not agreement; the row is an operator decision (record §10). libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 0); return p != 0; }
