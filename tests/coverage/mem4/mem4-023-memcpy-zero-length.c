// mem4-023: memcpy with length 0 is a no-op that returns dst.
#include <string.h>
int main(void) {
  int a = 1, b = 2;
  void *r = memcpy(&a, &b, 0);
  return a * 10 + (r == (void *)&a);
}
