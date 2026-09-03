/* Lean-side Core-level instrument (clean-exit variant): rand()'s Core
   body is REPLACED via cerberus-lean --libc with `alloc(8, 0)`
   (inject_rand.core); rand has no parameters, so nothing is allocated
   between x's create and the zero-size region. free(&x) is C11
   7.22.3.3p2 UB (Cerberus UB179a). __builtin_exit (std.core exit_proxy)
   ends the run before x's scope-exit kill would observe the dead object. */
#include <stdlib.h>
void __builtin_exit(int);
int main(void) {
  _Alignas(16) int x = 1;
  rand();
  free(&x);
  __builtin_exit(0);
  return 0;
}
