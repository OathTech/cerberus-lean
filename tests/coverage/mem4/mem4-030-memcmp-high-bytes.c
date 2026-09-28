// mem4-030: memcmp compares as unsigned char: 0x80 > 0x01, 0x00 < 0xff and a
// plain char -1 (0xff) > 1, so the signs are +, -, +. (Calls are sequenced:
// unsequenced memcmp calls multiply the interleavings.)
#include <string.h>
int main(void) {
  unsigned char a[2] = {0x80, 0x00}, b[2] = {0x01, 0x00};
  unsigned char c[1] = {0xff}, d[1] = {0x00};
  char e[1] = {-1}, f[1] = {1};
  int r1 = memcmp(a, b, 2);
  int r2 = memcmp(d, c, 1);
  int r3 = memcmp(e, f, 1);
  return (r1 > 0) * 100 + (r2 < 0) * 10 + (r3 > 0);
}
