/* Corner: _Bool in arithmetic promotes to int (ISO C11 6.3.1.1p2):
   b+b = 2, -b = -1, ~b = -2, b<<2 = 4, sizeof(b+b) = 4, b == 1. */
#include <stdio.h>
int main(void) {
  _Bool b = 1, z = 0;
  printf("%d %d %d %d %d %d %d\n", b + b, -b, ~b, b << 2, (int)sizeof(b + b), b == 1, z - 1);
  return 0;
}
