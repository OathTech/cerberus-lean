/* dynamic-addrs probe (a): the claimed bug shape.
   x is an automatic object; malloc(0) allegedly mints a zero-size dynamic
   region at the SAME base and pushes it on dynamic_addrs; free(&x) then
   passes is_dynamic and no UB179a fires.
   C11 7.22.3.3p2: free of a pointer not returned by malloc/calloc/realloc
   is undefined behaviour. Expected ISO: UB (Cerberus UB179a). */
#include <stdlib.h>
int main(void) {
  void *q;
  _Alignas(16) int x = 1;
  q = malloc(0);
  free(&x);
  return 0;
}
