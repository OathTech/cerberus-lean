// SB with seq_cst accesses and a seq_cst fence in each thread.
// The legacy donor refused this because SC_condition excludes fences.
// The current prototype must implement SC fences using a fence-aware
// reference; this seed is PENDING until that integration is validated.
// See README.md and the September 21 SC prototype charter.
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
