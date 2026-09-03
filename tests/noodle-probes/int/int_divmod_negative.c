/* Corner: truncation-toward-zero division and remainder sign with negative
   operands at every rank (ISO C11 6.5.5p6). */
#include <stdio.h>
int main(void) {
  int a = -7, b = 2;
  long la = -7000000000L, lb = 3;
  long long lla = -9223372036854775807LL - 1, llb = 2;
  unsigned ua = 0u - 7u; /* 4294967289 */
  short sa = -7; signed char ca = -7;
  printf("%d %d %d %d ", a / b, a % b, -a / -b, a % -b);      /* -3 -1 3 -1 */
  printf("%d %d ", b / a, b % a);                             /* 0 2 */
  printf("%ld %ld ", la / lb, la % lb);                        /* -2333333333 -1 */
  printf("%lld %lld ", lla / llb, lla % llb);                  /* -4611686018427387904 0 */
  printf("%u %u ", ua / 2u, ua % 3u);                          /* 2147483644 1 */
  printf("%d %d ", sa / 2, ca % 3);                            /* -3 -1 */
  printf("%d\n", (-2147483647-1) % 1);                         /* 0 */
  return 0;
}
