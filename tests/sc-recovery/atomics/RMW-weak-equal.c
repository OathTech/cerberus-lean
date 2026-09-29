// RMW-weak-equal — weak compare_exchange may fail spuriously even when the
// values are equal: outcome set {0, 5} (upstream RMW-weak-equal.core header).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0;
  int y = 0;
  int s = atomic_compare_exchange_weak_explicit(&x, &y, 1, memory_order_seq_cst, memory_order_seq_cst);
  // Sequence the result read: an unsequenced atomic/ordinary sum reaches SC-G07.
  int result_x = atomic_load_explicit(&x, memory_order_seq_cst);
  return result_x + 2 * y + 4 * s;
}
