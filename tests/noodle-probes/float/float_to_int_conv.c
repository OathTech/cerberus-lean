/* Corner: floating -> integer conversion truncates toward zero, at type
   boundaries, and for unsigned targets (ISO C11 6.3.1.4p1). All values
   representable: no UB. */
#include <stdio.h>
int main(void) {
  double a = 3.99, b = -3.99, c = -0.9, d = 2147483647.0, e = -2147483648.0;
  double f = 4294967295.0, g = 1.8e19, h = 255.9, i = -0.5;
  printf("%d %d %d ", (int)a, (int)b, (int)c);            /* 3 -3 0 */
  printf("%d %d ", (int)d, (int)e);                        /* 2147483647 -2147483648 */
  printf("%u ", (unsigned)f);                              /* 4294967295 */
  printf("%llu ", (unsigned long long)g);                  /* 18000000000000000000 */
  printf("%d ", (unsigned char)h);                         /* 255 */
  printf("%u ", (unsigned)i);                              /* 0 */
  printf("%lld ", (long long)9.2e18);                      /* 9200000000000000000 */
  printf("%ld\n", (long)(float)1e10);                      /* 10000000000 */
  return 0;
}
