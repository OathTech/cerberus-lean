// LB+rlx_rlx+rlx_rlx — the 2026-09-04 charter probe (relaxed LB).
// Outside F_SC: REFUSED. Under C11 the outcome set would be {0, 1, 2, 3}
// (tests.ml row). Measured "before": Specified(1) on both engines.
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0, y = 0;
  int r1, r2;
  {-{ { r1 = atomic_load_explicit(&x, memory_order_relaxed);
        atomic_store_explicit(&y, 1, memory_order_relaxed); }
  ||| { r2 = atomic_load_explicit(&y, memory_order_relaxed);
        atomic_store_explicit(&x, 1, memory_order_relaxed); } }-};
  return r1 + 2 * r2;
}
