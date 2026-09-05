// fence+sc+sc_sc — SB with seq_cst accesses ONLY and one seq_cst
// atomic_thread_fence: every access is inside F_SC, the FENCE is not (fences
// are outside SC_condition; charter 4.5). Target: REFUSE, by the scan's fence
// arm (`model refused: fence (Seq_cst) is outside the SC fragment`). Added by
// concurrency Phase 0 S7 (pre-merge audit M6: the corpus's other fence row is
// refused for its relaxed accesses first, so the fence arm was untested).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0, y = 0;
  int r1, r2;
  {-{ { atomic_store_explicit(&x, 1, memory_order_seq_cst);
        atomic_thread_fence(memory_order_seq_cst);
        r1 = atomic_load_explicit(&y, memory_order_seq_cst); }
  ||| { atomic_store_explicit(&y, 1, memory_order_seq_cst);
        atomic_thread_fence(memory_order_seq_cst);
        r2 = atomic_load_explicit(&x, memory_order_seq_cst); } }-};
  return r1 + 2 * r2;
}
