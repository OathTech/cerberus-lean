// WRC+sc+sc_sc+sc_sc — Write-to-Read Causality, seq_cst throughout.
// If z2 == 1 then z3 == 1 under SC. Encoding z1 + 2*z2 + 4*z3; the outcome
// set is derived by sc_reference.py (recorded in expectations.txt).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0, y = 0;
  int z1 = 0, z2, z3;
  {-{ { atomic_store_explicit(&x, 1, memory_order_seq_cst); }
  ||| { z1 = atomic_load_explicit(&x, memory_order_seq_cst);
        if (z1 == 1) atomic_store_explicit(&y, 1, memory_order_seq_cst); }
  ||| { z2 = atomic_load_explicit(&y, memory_order_seq_cst);
        z3 = atomic_load_explicit(&x, memory_order_seq_cst); } }-};
  return z1 + 2 * z2 + 4 * z3;
}
