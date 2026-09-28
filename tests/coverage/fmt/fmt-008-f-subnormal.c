// fmt-008: subnormal and tiny values: default precision prints zero; a long
// precision exposes the exact decimal digits of the smallest subnormal and of
// DBL_MIN.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%f|%.10f|%f]\n", 4.9406564584124654e-324, 2.2250738585072014e-308, -4.9406564584124654e-324);
  r += printf("[%.330f]\n", 4.9406564584124654e-324);
  r += printf("[%.320f]\n", 2.2250738585072014e-308);
  return r;
}
