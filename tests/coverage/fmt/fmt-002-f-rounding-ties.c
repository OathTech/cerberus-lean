// fmt-002: %.Nf rounding on EXACT binary ties (glibc rounds half to even on
// the exact value) and on near-ties that are not ties in binary.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%.0f|%.0f|%.0f|%.0f|%.0f|%.0f]\n", 0.5, 1.5, 2.5, 3.5, -0.5, -2.5);
  r += printf("[%.2f|%.2f|%.2f|%.1f|%.1f]\n", 0.125, 0.375, 0.625, 0.25, 0.75);
  r += printf("[%.2f|%.2f|%.3f|%.2f|%.1f]\n", 2.675, 1.005, 0.9995, 99.995, 0.05);
  r += printf("[%.3f|%.0f|%.0f]\n", 1.0005, 4503599627370497.0, 4503599627370496.5);
  return r;
}
