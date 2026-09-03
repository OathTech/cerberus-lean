/* Corner: shifts that are DEFINED or implementation-defined (ISO C11
   6.5.7): right shift of negative (impl-defined, arithmetic in Cerberus),
   promotion of narrow operands before shifting, shift of unsigned by
   width-1, shift of long long past 32. */
#include <stdio.h>
int main(void) {
  int m1 = -1; int m8 = -8;
  unsigned char uc = 0x80; unsigned short us = 0x8000;
  unsigned u1 = 1u; long long one = 1;
  printf("%d ", m1 >> 1);              /* -1 */
  printf("%d ", m8 >> 1);              /* -4 */
  printf("%d ", (-2147483647-1) >> 31); /* -1 */
  printf("%d ", uc << 1);              /* 256: promoted to int */
  printf("%d ", us << 15);             /* 1073741824 */
  printf("%u ", u1 << 31);             /* 2147483648 */
  printf("%lld ", one << 40);          /* 1099511627776 */
  printf("%lld ", (long long)-1 >> 63); /* -1 */
  printf("%u ", 0xFFFFFFFFu >> 31);    /* 1 */
  printf("%d ", (signed char)-1 >> 7);  /* -1 (promoted to int -1) */
  printf("%d\n", 1 << 0);
  return 0;
}
