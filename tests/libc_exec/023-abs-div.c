// 023: abs/labs/llabs and div/ldiv with negative operands (quotient truncates
// toward zero, remainder takes the dividend's sign).
#include <stdio.h>
#include <stdlib.h>
int main(void) {
  div_t a = div(-7, 2), b = div(7, -2);
  ldiv_t c = ldiv(-9000000000L, 7L);
  return printf("%d %ld %lld %d %d %d %d %ld %ld\n", abs(-5), labs(-6L), llabs(-7LL),
                a.quot, a.rem, b.quot, b.rem, c.quot, c.rem);
}
