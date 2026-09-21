// coherence+sc_sc_sc — single thread, two stores then a load (CoWW/CoWR):
// outcome set {1} (upstream tests.ml row coherence+rel_rel_acq [1]).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x;
  atomic_store_explicit(&x, 0, memory_order_seq_cst);
  atomic_store_explicit(&x, 1, memory_order_seq_cst);
  return atomic_load_explicit(&x, memory_order_seq_cst);
}
