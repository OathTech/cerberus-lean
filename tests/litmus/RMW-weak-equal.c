// RMW-weak-equal — weak compare_exchange may fail spuriously even when the
// values are equal: outcome set {0, 5} (upstream RMW-weak-equal.core header).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0;
  int y = 0;
  int s = atomic_compare_exchange_weak_explicit(&x, &y, 1, memory_order_seq_cst, memory_order_seq_cst);
  return atomic_load_explicit(&x, memory_order_seq_cst) + 2 * y + 4 * s;
}
