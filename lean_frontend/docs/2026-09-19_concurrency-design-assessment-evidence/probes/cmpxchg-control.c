#include <stdatomic.h>
int main(void) { _Atomic(int) x=0;int expected=0;return atomic_compare_exchange_strong_explicit(&x,&expected,1,memory_order_seq_cst,memory_order_seq_cst); }
