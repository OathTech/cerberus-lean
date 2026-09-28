// mem4-031: memcmp's returned VALUE (not only its sign) on differing bytes.
#include <string.h>
int main(void) {
  unsigned char a[3] = {1, 2, 0xf0}, b[3] = {1, 2, 0x10};
  int r1 = memcmp(a, b, 3), r2 = memcmp(b, a, 3);
  return (r1 + 1000) * 3 + r2 + 1000;
}
