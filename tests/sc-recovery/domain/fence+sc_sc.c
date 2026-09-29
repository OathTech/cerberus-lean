// SB with seq_cst fences between relaxed accesses.
// The relaxed accesses are outside the named SC execution mode and must
// not be silently strengthened. SC fences themselves are required work.
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0, y = 0;
  int r1, r2;
  {-{ { atomic_store_explicit(&x, 1, memory_order_relaxed);
        atomic_thread_fence(memory_order_seq_cst);
        r1 = atomic_load_explicit(&y, memory_order_relaxed); }
  ||| { atomic_store_explicit(&y, 1, memory_order_relaxed);
        atomic_thread_fence(memory_order_seq_cst);
        r2 = atomic_load_explicit(&x, memory_order_relaxed); } }-};
  return r1 + 2 * r2;
}
