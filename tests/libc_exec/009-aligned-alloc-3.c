/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/mem/aligned_alloc_3.c — non-power-of-two alignment through the allocator's quomod (Z-13/Z2-M-05 control: the new allocator mirror).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing libc_exec MATCH row. */
/* Z2 CONTROL: non-power-of-two alignment through the allocator arithmetic
   (impl_mem.ml:1247-1257 quomod/erem vs CerbMem.alignDown). libc mode. */
#include <stdlib.h>
#include <stdint.h>
int main(void) { void *p = aligned_alloc(3, 9); return (int)((uintptr_t)p % 3 == 0) + 10; }
