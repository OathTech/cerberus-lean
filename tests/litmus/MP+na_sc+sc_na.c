// MP+na_sc+sc_na — Message Passing: non-atomic payload x, seq_cst flag y.
// Race-free (the non-atomic read of x is hb-after the write when y reads 1);
// outcome set {1, 2} (upstream tests.ml row MP+na_rel+acq_na [1; 2]).
#include <stdatomic.h>
int main(void) {
  int x = 0;
  _Atomic(int) y = 0;
  int z1, z2;
  {-{ { x = 1;
        atomic_store_explicit(&y, 1, memory_order_seq_cst); }
  ||| { z1 = atomic_load_explicit(&y, memory_order_seq_cst);
        if (z1 == 1) z2 = x; else z2 = 2; } }-};
  return z2;
}
