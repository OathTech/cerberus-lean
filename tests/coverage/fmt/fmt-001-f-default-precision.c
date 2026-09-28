// fmt-001: printf %f with the default precision (6) — CerbFloat.formatFixed
// end to end: zero, integers, fractions, and values that round at the 6th
// decimal (5e-7 rounds up, 4.9e-7 rounds down). Result = chars written.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%f|%f|%f|%f]\n", 0.0, 1.0, 123.456, 1e-6);
  r += printf("[%f|%f|%f|%f]\n", 5e-7, 4.9e-7, 0.0000015, 123456789.123456789);
  r += printf("[%lf|%f]\n", 2.5, 1.0 / 3.0);
  return r;
}
