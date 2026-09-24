// RMW-strong-equal — strong compare_exchange with equal values always
// succeeds: x becomes 1, y stays 0, success 1: outcome set {5}
// (upstream tests/concurrency/RMW-strong-equal.core header).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0;
  int y = 0;
  int s = atomic_compare_exchange_strong_explicit(&x, &y, 1, memory_order_seq_cst, memory_order_seq_cst);
  // Sequence the result read: an unsequenced atomic/ordinary sum reaches SC-G07.
  int result_x = atomic_load_explicit(&x, memory_order_seq_cst);
  return result_x + 2 * y + 4 * s;
}
