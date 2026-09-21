// LB+sc_sc+sc_sc — Load Buffering with seq_cst atomics.
// SC forbids both loads reading 1: outcome set {0, 1, 2} (upstream tests.ml
// row LB+Rsc_Wsc+Rsc_Wsc [0; 1; 2]).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0, y = 0;
  int r1, r2;
  {-{ { r1 = atomic_load_explicit(&x, memory_order_seq_cst);
        atomic_store_explicit(&y, 1, memory_order_seq_cst); }
  ||| { r2 = atomic_load_explicit(&y, memory_order_seq_cst);
        atomic_store_explicit(&x, 1, memory_order_seq_cst); } }-};
  return r1 + 2 * r2;
}
