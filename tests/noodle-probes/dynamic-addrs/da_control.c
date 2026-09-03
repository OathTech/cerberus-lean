/* dynamic-addrs probe (b): CONTROL — no malloc(0); free(&x) must be UB179a.
   C11 7.22.3.3p2. */
#include <stdlib.h>
int main(void) {
  _Alignas(16) int x = 1;
  free(&x);
  return 0;
}
