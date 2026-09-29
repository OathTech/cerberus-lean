// RMW-strong-unequal — expected 1 vs actual 0: fails, y := 0, success 0:
// outcome set {0} (upstream RMW-strong-unequal.core header).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0;
  int y = 1;
  int s = atomic_compare_exchange_strong_explicit(&x, &y, 1, memory_order_seq_cst, memory_order_seq_cst);
  // Sequence the result read: an unsequenced atomic/ordinary sum reaches SC-G07.
  int result_x = atomic_load_explicit(&x, memory_order_seq_cst);
  return result_x + 2 * y + 4 * s;
}
