// mem4-025: a pointer rebuilt from its bytes by memcpy through a char buffer
// (the byte-array round trip) still points to its object.
#include <string.h>
int main(void) {
  int x = 42;
  int *p = &x, *q;
  unsigned char buf[sizeof(int *)];
  memcpy(buf, &p, sizeof p);
  memcpy(&q, buf, sizeof q);
  *q += 1;
  return x;
}
