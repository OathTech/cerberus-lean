/* Corner: malloc(0) returns NULL or a unique pointer that may be freed
   (ISO C11 7.22.3p1, impl-defined). Observes only null-ness and that
   free succeeds. */
#include <stdlib.h>
int main(void) {
  void *p = malloc(0);
  void *q = malloc(0);
  int r = (p == 0) + 2 * (q == 0);
  free(p); free(q);
  return r;
}
