/* AUDITOR reproducer variant v2-declfirst-plus7: request = cursor + 7 -> z = -7: pristine z' = -7 + 9 = 2 ACTIVE; fork: out of memory */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;   /* every local created BEFORE the first malloc: no create between the two calls */
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a + 7));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
