/* Z2 probe (CerbMem / std.core aligned_alloc_proxy): std.core:385 evaluates
   `size rem_t align` BEFORE alloc, with no UB045 guard. align == 0 makes the
   oracle's Z.rem raise Division_by_zero (impl_mem.ml:2481-2482 via :11) while
   Lean's Int.tmod x 0 = x is total (CerbMem.lean integerRem_t doc: "unreachable
   behind Core's division-by-zero UB guards" — this path has no guard).
   libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 8); return p != 0; }
