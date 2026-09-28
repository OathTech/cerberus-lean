// mem4-024: copy only half of a pointer object's bytes over another pointer
// holding a different address, then use it.
#include <string.h>
int main(void) {
  int x = 1, y = 2;
  int *p = &x, *q = &y;
  memcpy(&q, &p, 4);
  return q == p ? 10 : 20;
}
