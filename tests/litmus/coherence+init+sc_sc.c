// coherence+init+sc_sc — as coherence+sc_sc_sc but a thread is created between
// the first and second store: exercises the asw edges. Outcome set {1}
// (upstream tests.ml row coherence+init+rel_acq [1]).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x;
  int a;
  atomic_store_explicit(&x, 0, memory_order_seq_cst);
  {-{ { atomic_store_explicit(&x, 1, memory_order_seq_cst);
        a = atomic_load_explicit(&x, memory_order_seq_cst); }
  ||| { } }-};
  return a;
}
