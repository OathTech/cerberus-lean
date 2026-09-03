/* Corner: abs/labs/llabs and div/ldiv truncation toward zero (ISO C11
   7.22.6). Sequenced. */
#include <stdlib.h>
#include <stdio.h>
int main(void) {
  div_t d = div(7, -2); ldiv_t l = ldiv(-7L, 2L);
  int a = abs(-5); long b = labs(-6L); long long c = llabs(-7LL);
  printf("%d %ld %lld %d %d %ld %ld\n", a, b, c, d.quot, d.rem, l.quot, l.rem);   /* 5 6 7 -3 1 -3 -1 */
  return 0;
}
