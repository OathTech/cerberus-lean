// SB+rel_acq+rel_acq — upstream cerberus tests/concurrency/SB+rel_acq+rel_acq.c
// (deleted upstream 2017-04-27, 9efe31119; recovered from 9efe31119^; the
// `{{{ ||| }}}` spelling is replaced by today's `{-{ ||| }-}`).
// Outside F_SC (release/acquire): REFUSED by the SC instance. Under C11 the
// outcome set would be {0, 1, 2, 3} (tests.ml row).
#include <stdatomic.h>
int main() {
  atomic_int x=0, y=0;
  int z1, z2;
  {-{ { atomic_store_explicit(&y, 1, memory_order_release);
        z1 = atomic_load_explicit(&x, memory_order_acquire); }
  ||| { atomic_store_explicit(&x, 1, memory_order_release);
        z2 = atomic_load_explicit(&y, memory_order_acquire); }  }-};
  return z1 + (2 * z2);
}
