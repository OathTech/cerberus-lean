/* Corner: compound assignment of a floating rhs to an integer lvalue:
   computed in double, converted back with truncation (ISO C11 6.5.16.2p3). */
#include <stdio.h>
int main(void) {
  int i = 5; i += 0.7;                /* 5 */
  int j = 5; j *= 1.5;                /* 7 */
  int k = 7; k /= 2.0;                /* 3 */
  int l = 3; l /= 0.5;                /* 6 */
  char c = 100; c += 20.5;            /* 120 */
  unsigned u = 0; u -= 0.5;           /* 0 */
  int m = 5; m -= 5.5;                /* 0 */
  int n = 1; n *= -0.999;             /* 0 */
  printf("%d %d %d %d %d %u %d %d\n", i, j, k, l, c, u, m, n);
  return 0;
}
