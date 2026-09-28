// fmt-005: negative zero under %f, with the '+' and ' ' flags, and negative
// values that round to zero. A real -0.0 is produced by multiplication
// (0.0 * -1.0) and by underflow (-1e-300 * 1e-300); both print "-0.000000".
// OBSERVED in both engines (2026-09-28): unary minus does NOT produce a
// negative zero in the model (-0.0 and -z with z = 0.0 evaluate to +0.0, as
// 0 - x would), so those print "0.000000" where C/glibc prints "-0.000000".
#include <stdio.h>
int main(void) {
  double un = -0.0, z = 0.0, unz = -z;
  double nz = 0.0 * -1.0, uf = -1e-300 * 1e-300;
  int r = 0;
  r += printf("[%f|%f|%f|%f|%.0f|%.2f]\n", nz, uf, un, unz, nz, -0.004);
  r += printf("[%+f|% f|%+.0f|%+f|% f|%-+8.1f|%08.1f]\n", nz, nz, -0.4, 0.0, 0.0, nz, nz);
  r += printf("[%.0f|%.1f|%f]\n", -0.5, -0.04, -1e-9);
  return r;
}
