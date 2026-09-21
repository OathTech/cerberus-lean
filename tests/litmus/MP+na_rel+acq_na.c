// MP+na_rel+acq_na — upstream tests/concurrency/MP+na_rel+acq_na.c
// (recovered from 9efe31119^, braces respelled). Outside F_SC: REFUSED.
// Under C11 the outcome set would be {1, 2} (tests.ml row).
#include <stdatomic.h>
int main(void) {
  int x = 0;
  _Atomic(int) y = 0;
  int z1, z2;
  {-{ { x = 1;
        atomic_store_explicit(&y, 1, memory_order_release); }
  ||| { z1 = atomic_load_explicit(&y, memory_order_acquire);
        if (z1 == 1)
          z2 = x;
        else
          z2 = 2; }  }-};
  return z2;
}
