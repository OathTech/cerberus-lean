/* AUDITOR reproducer variant w1-minus7: z = (a-8) - (a-7) = -1: pristine z' = -1 + 7 = 6 ACTIVE (align 8); fork: out of memory
   Facts used (measured, .tmp/audit/repro/variants.out.txt): malloc_proxy (std.core:350) takes a POINTER to its
   argument, so the call site create()s an 8-byte temporary BEFORE alloc runs — the cursor at alloc is a - 8;
   malloc's alignment IvMaxAlignment is <= 8 (v5: request a-16 landed at low byte 8). */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a - 7));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
