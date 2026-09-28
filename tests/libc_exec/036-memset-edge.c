// 036: memset converts the value to unsigned char (0x1ff -> 0xff), length 0
// writes nothing, a partial range leaves the rest.
#include <stdio.h>
#include <string.h>
int main(void) {
  unsigned char a[6] = {1, 2, 3, 4, 5, 6};
  memset(a + 1, 0x1ff, 3);
  memset(a, 0, 0);
  void *r = memset(a + 5, -2, 1);
  return printf("%d %d %d %d %d %d %d\n", a[0], a[1], a[2], a[3], a[4], a[5], r == a + 5);
}
