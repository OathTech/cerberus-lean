// fmt-006: infinities under %f (an overflowing literal is +inf); width, '-',
// '+' and precision applied to "inf".
#include <stdio.h>
int main(void) {
  double inf = 1e309;
  double ninf = -1e309;
  int r = 0;
  r += printf("[%f|%f|%.0f|%.3f]\n", inf, ninf, inf, ninf);
  r += printf("[%8f|%-8f|%+f|%8.2f]\n", inf, inf, inf, ninf);
  return r;
}
