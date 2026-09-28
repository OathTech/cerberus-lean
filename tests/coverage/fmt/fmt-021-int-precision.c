// fmt-021: %d precision: minimum digit count, the zero value with precision 0
// prints no digits, and precision disables the '0' flag.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%.3d|%08.3d|%.0d|%.0d|%5.0d|%.10d]\n", 42, 42, 0, 7, 0, -42);
  r += printf("[%.d|%-6.3d|%+.3d|%.1d|%.2d]\n", 0, 5, 5, 0, -1);
  return r;
}
