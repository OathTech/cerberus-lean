/* AUDITOR reproducer variant v3-declfirst-plus8: request = cursor + 8 -> z = -8: m = 8, z' = 0 -> BOTH kill (window edge control) */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;   /* every local created BEFORE the first malloc: no create between the two calls */
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a + 8));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
