/* AUDITOR reproducer variant v5-declfirst-minus16: request = cursor - 16 -> z = 16 -> BOTH active at 16 (normal regime control; low byte 16) */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;   /* every local created BEFORE the first malloc: no create between the two calls */
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a - 16));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
