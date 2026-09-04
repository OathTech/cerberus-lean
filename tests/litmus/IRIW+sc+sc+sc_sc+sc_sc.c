// IRIW+sc+sc+sc_sc+sc_sc — Independent Reads of Independent Writes, seq_cst.
// SC forbids the two readers seeing the writes in different orders
// (z1=1,z2=0,z3=1,z4=0 = encoding 5): outcome set {0..15} \ {5}
// (upstream tests.ml row IRIW+Wsc+Wsc+Rsc_Rsc+Rsc_Rsc).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0, y = 0;
  int z1, z2, z3, z4;
  {-{ { atomic_store_explicit(&x, 1, memory_order_seq_cst); }
  ||| { atomic_store_explicit(&y, 1, memory_order_seq_cst); }
  ||| { z1 = atomic_load_explicit(&x, memory_order_seq_cst);
        z2 = atomic_load_explicit(&y, memory_order_seq_cst); }
  ||| { z3 = atomic_load_explicit(&y, memory_order_seq_cst);
        z4 = atomic_load_explicit(&x, memory_order_seq_cst); } }-};
  return z1 + 2 * (z2 + 2 * (z3 + 2 * z4));
}
