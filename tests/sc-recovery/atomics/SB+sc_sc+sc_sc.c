// SB+sc_sc+sc_sc — Store Buffering with seq_cst atomics.
// SC forbids both loads reading 0: outcome set {1, 2, 3} (upstream tests.ml
// row SB+Wsc_Rsc+Wsc_Rsc [1; 2; 3]; sc_reference.py agrees).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0, y = 0;
  int r1, r2;
  {-{ { atomic_store_explicit(&x, 1, memory_order_seq_cst);
        r1 = atomic_load_explicit(&y, memory_order_seq_cst); }
  ||| { atomic_store_explicit(&y, 1, memory_order_seq_cst);
        r2 = atomic_load_explicit(&x, memory_order_seq_cst); } }-};
  return r1 + 2 * r2;
}
