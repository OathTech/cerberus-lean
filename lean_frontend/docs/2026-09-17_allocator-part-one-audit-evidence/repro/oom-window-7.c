/* AUDITOR reproducer (2026-09-17): is the allocator's exhausted regime reachable at UPSTREAM'S bound?
   malloc is std.core:350 `alloc(IvMaxAlignment, size)` (align 16). After malloc(1) the cursor IS the
   returned address q (impl_mem.ml allocator: last_address := addr). A request of q+1 bytes makes
   z = last_address - sz = -1: pristine b9aeedcb4 rounds z' = z + (z mod 16) = 14 and SUCCEEDS
   (draft 44's defect); the fork after remedy 1 kills with "out of memory". */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  char *q = malloc(1);
  if (q == NULL) return 3;
  size_t sz = (size_t)(uintptr_t)q + 7;
  char *p = malloc(sz);
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);   /* pristine: 2 */
}
