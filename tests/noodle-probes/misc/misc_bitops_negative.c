/* Corner: bitwise operators on negative two's-complement values
   (ISO C11 6.5.10-12, 6.2.6.2). */
#include <stdio.h>
int main(void) {
  int m1 = -1, m8 = -8;
  printf("%d %d %d %d %d %d %d\n", m1 & 0xFF, ~m1, m1 ^ 1, 1 | -2, m8 & ~7, (m1 >> 31) & 1, -1 >> 31);   /* 255 0 -2 -1 -8 1 -1 */
  return 0;
}
