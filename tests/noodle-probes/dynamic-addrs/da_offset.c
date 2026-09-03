/* dynamic-addrs probe (c): base coincidence — return (&x - q) in bytes
   (mod 256 via the exit status). 0 => malloc(0) returned the base of x.
   Deterministic concrete-model addresses; UB-free. */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  void *q;
  _Alignas(16) int x = 1;
  q = malloc(0);
  if (q == NULL) return 255;
  return (int)((uintptr_t)&x - (uintptr_t)q);
}
