/* Corner: a large (4 GiB + 2) malloc that is never touched. ISO allows
   either NULL or a valid pointer (7.22.3.4). Observer for the byte-
   materialising representation (parity-detective RC-3): the oracle
   allocates lazily and returns 2; gcc returns 2 (overcommit). */
#include <stdlib.h>
int main(void) {
  void *p = malloc(4294967298ul);
  return p == 0 ? 1 : 2;
}
