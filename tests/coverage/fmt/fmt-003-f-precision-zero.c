// fmt-003: %.0f (no decimal point) and the '#' flag on %f, plus rounding that
// carries into a new integer digit.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%.0f|%.0f|%.0f|%.0f|%.0f]\n", 0.4, 0.6, 9.5, 99.5, 999999.5);
  r += printf("[%#.0f|%#f|%#.1f]\n", 3.0, 3.0, 3.0);
  r += printf("[%.6f|%.6f|%.2f|%.0f]\n", 9.9999995, 0.9999999, 999.995, 1e15 + 0.5);
  return r;
}
