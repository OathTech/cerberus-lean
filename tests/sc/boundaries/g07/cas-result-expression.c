// Original CAS seed: the final atomic read is unsequenced with ordinary reads.
// RMW-strong-equal — strong compare_exchange with equal values always
// succeeds: x becomes 1, y stays 0, success 1: outcome set {5}
// (upstream tests/concurrency/RMW-strong-equal.core header).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0;
  int y = 0;
  int s = atomic_compare_exchange_strong_explicit(&x, &y, 1, memory_order_seq_cst, memory_order_seq_cst);
  return atomic_load_explicit(&x, memory_order_seq_cst) + 2 * y + 4 * s;
}
