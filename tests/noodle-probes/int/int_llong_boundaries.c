/* Corner: long long / unsigned long long boundaries and the type of a hex
   constant that only fits unsigned long (ISO C11 6.4.4.1p5, 6.2.5p9). */
#include <stdio.h>
int main(void) {
  unsigned long long m = 18446744073709551615ull;
  printf("%llu ", m + 1);                          /* 0 */
  printf("%llu ", (unsigned long long)-1 >> 63);   /* 1 */
  printf("%d ", (int)sizeof(0x8000000000000000));  /* 8 */
  printf("%d ", 0x8000000000000000 > 0);           /* 1: unsigned long */
  printf("%d ", -0x8000000000000000 > 0);          /* 1 */
  printf("%lld ", (long long)0x8000000000000000);  /* -9223372036854775808 */
  printf("%d ", (int)9223372036854775807LL);       /* -1 */
  printf("%lld ", 9223372036854775807LL % -1);     /* 0 */
  printf("%lld\n", (-9223372036854775807LL-1) / 1);/* LLONG_MIN */
  return 0;
}
