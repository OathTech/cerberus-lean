// fmt-004: precisions beyond 17 significant digits: formatFixed must print the
// EXACT binary value's decimal expansion, not a shortest round-trip form.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%.17f|%.20f|%.30f]\n", 0.1, 0.1, 1.0 / 3.0);
  r += printf("[%.55f]\n", 0.1);
  r += printf("[%.60f]\n", 1e-50);
  r += printf("[%.25f|%.40f]\n", 2.0 / 3.0, 0.5);
  return r;
}
