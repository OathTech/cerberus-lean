// hb-mo-cycle+Wsc_Wsc_Rsc+Wsc_Wsc_Rsc — both loads reading 0 would need a
// cycle in the SC order: outcome set {1, 2, 3} (upstream tests.ml row).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x, y;
  int a1, a2;
  {-{ { atomic_store_explicit(&x, 0, memory_order_seq_cst);
        atomic_store_explicit(&y, 1, memory_order_seq_cst);
        a1 = atomic_load_explicit(&y, memory_order_seq_cst); }
  ||| { atomic_store_explicit(&y, 0, memory_order_seq_cst);
        atomic_store_explicit(&x, 1, memory_order_seq_cst);
        a2 = atomic_load_explicit(&x, memory_order_seq_cst); } }-};
  return a1 + 2 * a2;
}
