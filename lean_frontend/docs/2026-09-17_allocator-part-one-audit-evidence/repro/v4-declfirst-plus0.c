/* AUDITOR reproducer variant v4-declfirst-plus0: request = cursor exactly -> z = 0: m = 0, z' = 0 -> BOTH kill (control) */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;   /* every local created BEFORE the first malloc: no create between the two calls */
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
