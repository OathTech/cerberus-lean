// fmt-009: huge magnitudes: DBL_MAX has 309 integer digits under %f; 1e23 is
// not exactly representable; 2^53 + 1 is not representable either.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%f]\n", 1.7976931348623157e308);
  r += printf("[%.0f|%.0f|%.1f]\n", 1e23, -1e22, 9007199254740993.0);
  r += printf("[%.3f]\n", 123456789012345678901234567890.0);
  return r;
}
