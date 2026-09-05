// SB+sc_sc+sc_sc+globals — Store Buffering with seq_cst atomics, the shared
// objects at FILE SCOPE (static initialisation precedes program startup, C11
// 5.1.2p1 / 6.2.4p3). Same outcome set as the block-scope row: {1, 2, 3}.
// Added by concurrency Phase 0 S7 (pre-merge audit F1: the file-scope
// initialisation stores had no sb edge into main and every such program read
// UB005). sc_reference.py agrees.
#include <stdatomic.h>
_Atomic(int) x = 0, y = 0;
int main(void) {
  int r1, r2;
  {-{ { atomic_store_explicit(&x, 1, memory_order_seq_cst);
        r1 = atomic_load_explicit(&y, memory_order_seq_cst); }
  ||| { atomic_store_explicit(&y, 1, memory_order_seq_cst);
        r2 = atomic_load_explicit(&x, memory_order_seq_cst); } }-};
  return r1 + 2 * r2;
}
