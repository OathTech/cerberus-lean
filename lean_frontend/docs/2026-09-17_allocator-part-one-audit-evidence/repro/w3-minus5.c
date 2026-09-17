/* AUDITOR reproducer variant w3-minus5: z = -3: pristine z' = -3 + 5 = 2 ACTIVE; fork: out of memory
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
  p = malloc((size_t)(a - 5));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
