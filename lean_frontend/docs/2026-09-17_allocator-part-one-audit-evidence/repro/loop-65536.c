/* AUDITOR reproducer (2026-09-17): the allocator's EXHAUSTED regime reached at UPSTREAM'S OWN bound
   (last_address = 0xFFFFFFFFFFFF) by an ordinary program. Allocation in this model is bookkeeping, so
   65536 successful malloc(0xFFFFFFF0) calls (std.core:350 alloc(IvMaxAlignment=16, size)) lower the
   cursor by 65536 * (2^32 - 16) ~ 2^48 to ~0xFFF90. The final request of cursor+1 bytes makes
   z = last_address - sz = -1: pristine b9aeedcb4 (impl_mem.ml:1253) rounds z' = z + (z mod 16) = 14
   and SUCCEEDS (draft 44's defect: an object at 14 overlapping every live object); the fork after
   remedy 1 kills with "Concrete.allocator: failed (out of memory)". */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a = 0;
  for (unsigned i = 0; i < 65536u; i++) { char *p = malloc(0xFFFFFFF0u); if (!p) return 3; a = (uintptr_t)p; }
  char *q = malloc((size_t)(a + 1));
  if (!q) return 4;
  return (int)((uintptr_t)q & 0xff);   /* pristine: 14 */
}
