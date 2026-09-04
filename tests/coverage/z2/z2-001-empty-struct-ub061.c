/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/mem/empty_struct.c — GNU empty struct: UB061 on the shared front end (refutes the layout-family % 0 route, Z2-M-11).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc UB_MATCH row. */
/* Z2 probe (layout): a member-less struct has alignof 0 upstream
   (impl_mem.ml:228-252 fold seed 0) so sizeof's `modulus max_offset align`
   (:169-171) raises Division_by_zero; Lean's Nat `% 0` yields the dividend
   (CerbMem.lean offsetsofMembers doc). Reachable only if the shared front end
   accepts the GNU empty struct. nolibc. */
struct e {};
int main(void) { return (int)sizeof(struct e) + 10; }
