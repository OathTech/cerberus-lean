// MP+na_sc+sc_na+globals — Message Passing (non-atomic payload, seq_cst flag),
// shared objects at FILE SCOPE. Same outcome set as the block-scope row:
// {1, 2}. Added by concurrency Phase 0 S7 (pre-merge audit F1). sc_reference.py
// agrees.
#include <stdatomic.h>
int x = 0;
_Atomic(int) y = 0;
int main(void) {
  int z1, z2;
  {-{ { x = 1;
        atomic_store_explicit(&y, 1, memory_order_seq_cst); }
  ||| { z1 = atomic_load_explicit(&y, memory_order_seq_cst);
        if (z1 == 1) z2 = x; else z2 = 2; } }-};
  return z2;
}
