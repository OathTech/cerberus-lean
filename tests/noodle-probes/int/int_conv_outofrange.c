/* Corner: implementation-defined conversion of out-of-range integers to
   signed types (ISO C11 6.3.1.3p3; Cerberus impl: two's complement wrap). */
#include <stdio.h>
int main(void) {
  signed char sc = 200;              /* -56 */
  short sh = 70000;                  /* 4464 */
  int i = 3000000000u;               /* -1294967296 */
  unsigned char uc = -1;             /* 255 */
  int j = (long)0x100000001L;        /* 1 */
  long long ll = 18446744073709551615ull; /* -1 */
  short sh2 = -70000;                /* -4464 */
  signed char sc2 = 128;             /* -128 */
  printf("%d %d %d %d %d %lld %d %d\n", sc, sh, i, uc, j, ll, sh2, sc2);
  return 0;
}
