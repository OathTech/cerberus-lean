/* AUDITOR reproducer variant v1-declfirst-plus1: request = cursor + 1 -> z = -1: pristine z' = -1 + 15 = 14 ACTIVE; fork: out of memory */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;   /* every local created BEFORE the first malloc: no create between the two calls */
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a + 1));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
