// LB+acq_rel+acq_rel — upstream tests/concurrency/LB+acq_rel+acq_rel.c
// (recovered from 9efe31119^, braces respelled). Outside F_SC: REFUSED.
// Under C11 the outcome set would be {0, 1, 2} (tests.ml row).
#include <stdatomic.h>
int main() {
  _Atomic(int) x=0, y=0;
  int z1, z2;
  {-{ { z1 = atomic_load_explicit(&x, memory_order_acquire);
        atomic_store_explicit(&y, 1, memory_order_release); }
  ||| { z2 = atomic_load_explicit(&y, memory_order_acquire);
        atomic_store_explicit(&x, 1, memory_order_release); }  }-};
  return z1 + (2 * z2);
}
