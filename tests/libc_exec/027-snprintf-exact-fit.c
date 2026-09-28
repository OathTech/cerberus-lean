// 027: snprintf at the exact-fit boundaries: n = len + 1 (fits), n = len
// (last char dropped), n = 1 (only the NUL); the bytes after the NUL are
// untouched.
#include <stdio.h>
#include <string.h>
int main(void) {
  char a[8], b[8], c[8];
  memset(a, '#', 8); memset(b, '#', 8); memset(c, '#', 8);
  int ra = snprintf(a, 6, "%s", "hello");
  int rb = snprintf(b, 5, "%s", "hello");
  int rc = snprintf(c, 1, "%d", 99);
  return printf("%d:%s:%c %d:%s:%c %d:%d:%c\n", ra, a, a[6], rb, b, b[5], rc, c[0], c[1]);
}
