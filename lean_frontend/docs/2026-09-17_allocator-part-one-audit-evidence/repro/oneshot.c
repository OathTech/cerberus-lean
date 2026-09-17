/* AUDITOR reproducer (2026-09-17): the allocator's EXHAUSTED regime reached at UPSTREAM'S OWN bound
   (last_address = 0xFFFFFFFFFFFF) by ONE ordinary malloc. After malloc(1) the cursor IS the returned
   address q (impl_mem.ml allocator: last_address := addr; std.core:350 malloc = alloc(IvMaxAlignment, size),
   align 16). A request of q+1 bytes (size_t is 64-bit here: sizeof(size_t)=8) makes
   z = last_address - sz = -1: pristine b9aeedcb4 (impl_mem.ml:1253) rounds z' = z + (z mod 16) = 14 and
   SUCCEEDS — draft 44's defect, an object at address 14 overlapping every live object; the fork after
   remedy 1 kills with "Concrete.allocator: failed (out of memory)".
   NOTE the parenthesisation (size_t)(a + 1): `(size_t)a + 1` is truncated to 32 bits by both engines
   (a separate, pre-existing shared-model observation, .tmp/audit/repro/trunc.c). */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  char *q = malloc(1);
  if (q == NULL) return 3;
  uintptr_t a = (uintptr_t)q;
  char *p = malloc((size_t)(a + 1));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);   /* pristine: 14 */
}
