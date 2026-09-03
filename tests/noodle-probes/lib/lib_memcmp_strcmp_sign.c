/* Corner: memcmp/strcmp compare as unsigned char and return sign only
   matters; high-bit bytes compare greater (ISO C11 7.24.4.1p2, 7.24.4.2). */
#include <string.h>
#include <stdio.h>
int main(void) {
  unsigned char x[2] = {0x80, 0}, y[2] = {0x7f, 0};
  int a = memcmp(x, y, 1) > 0;              /* 1 */
  int b = strcmp((char*)x, (char*)y) > 0;   /* 1 */
  int c = strcmp("abc", "abd") < 0;         /* 1 */
  int d = strcmp("", "") == 0;              /* 1 */
  int e = memcmp("abc", "abc", 0) == 0;     /* 1 */
  printf("%d %d %d %d %d\n", a, b, c, d, e);
  return 0;
}
