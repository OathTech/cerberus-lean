/* AUDITOR witness, nolibc, self-checking: exit = 100 + low byte of p if the new object CONTAINS the live 1-byte
   object q (overlap) and p is 8-aligned; = low byte of p otherwise; 4 if malloc failed (fork/Lean: killed). */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q; size_t sz;
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  sz = (size_t)(a - 7);
  p = malloc(sz);
  if (p == NULL) return 4;
  int low = (int)((uintptr_t)p & 0xff);
  int overlap = (uintptr_t)p + sz > a - 8;   /* the new object ends ABOVE the cursor at alloc time (a-8: malloc_proxy's 8-byte argument temporary is the most recent live object) */
  int aligned8 = (((uintptr_t)p) % 8) == 0;
  return low + (overlap ? 100 : 0) + (aligned8 ? 50 : 0);   /* pristine: 106 = address 6, extends past the cursor (overlaps the live temporary), NOT 8-aligned; fork: killed */
}
