/* Z2 probe (layout): a member-less struct has alignof 0 upstream
   (impl_mem.ml:228-252 fold seed 0) so sizeof's `modulus max_offset align`
   (:169-171) raises Division_by_zero; Lean's Nat `% 0` yields the dividend
   (CerbMem.lean offsetsofMembers doc). Reachable only if the shared front end
   accepts the GNU empty struct. nolibc. */
struct e {};
int main(void) { return (int)sizeof(struct e) + 10; }
