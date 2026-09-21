// RMW-strong-unequal — expected 1 vs actual 0: fails, y := 0, success 0:
// outcome set {0} (upstream RMW-strong-unequal.core header).
#include <stdatomic.h>
int main(void) {
  _Atomic(int) x = 0;
  int y = 1;
  int s = atomic_compare_exchange_strong_explicit(&x, &y, 1, memory_order_seq_cst, memory_order_seq_cst);
  return atomic_load_explicit(&x, memory_order_seq_cst) + 2 * y + 4 * s;
}
