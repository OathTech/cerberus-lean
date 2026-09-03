/* Corner: integer -> floating conversion rounds when the integer is not
   exactly representable (ISO C11 6.3.1.4p2), float and double. */
#include <stdio.h>
int main(void) {
  printf("%d ", (float)16777217 == 16777216.0f);              /* 1 */
  printf("%d ", (double)9007199254740993LL == 9007199254740992.0); /* 1 */
  printf("%d ", (float)0xFFFFFFFFu == 4294967296.0f);         /* 1 */
  printf("%d ", (float)16777219 == 16777220.0f);              /* 1 (ties-to-even) */
  printf("%d ", (double)(1LL << 62) == 4611686018427387904.0);/* 1 */
  printf("%lld ", (long long)(double)9007199254740993LL);     /* 9007199254740992 */
  printf("%d\n", (int)(float)2147483520);                     /* 2147483520 exact */
  return 0;
}
