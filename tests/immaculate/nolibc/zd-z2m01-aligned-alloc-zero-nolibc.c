/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01, nolibc witness; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero_nolibc.c — the same std.core:385 `size rem_t align`
   through the ailname redirect in --nolibc mode (the mode does not matter). Oracle: Division_by_zero
   exit 125; Lean: `Undefined {ub: "DUMMY(align_alloc)", …}`. RE-CLASSIFIED [USER 2026-09-03] (the
   logical-semantics referent ruling): kind-2 oracle artifact, not mirrored; pinned ORACLE_CRASH |
   L=UB:DUMMY(align_alloc) pending the operator's decision on the logical meaning (record §10). */
extern void *aligned_alloc(unsigned long, unsigned long);
int main(void) { void *p = aligned_alloc(0, 8); return p != 0; }
