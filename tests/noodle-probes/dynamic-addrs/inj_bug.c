/* Lean-side Core-level instrument: rand() has NO parameters (so no
   argument temporaries are created between x's create and the alloc);
   its Core body is REPLACED via --libc with `alloc(8, 0)` (see
   inject_rand.core). free(&x) is C11 7.22.3.3p2 UB: expected UB179a. */
#include <stdlib.h>
int main(void) {
  _Alignas(16) int x = 1;
  rand();
  free(&x);
  return 0;
}
