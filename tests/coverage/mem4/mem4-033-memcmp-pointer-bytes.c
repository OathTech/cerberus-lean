// mem4-033: memcmp over the representation of two pointer objects (equal and
// unequal addresses).
#include <string.h>
int main(void) {
  int x, y;
  int *p = &x, *p2 = &x, *q = &y;
  int r1 = memcmp(&p, &p2, sizeof p);
  int r2 = memcmp(&p, &q, sizeof p);
  return (r1 == 0) * 10 + (r2 != 0);
}
