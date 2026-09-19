#include <stdatomic.h>
int main(void) { _Atomic(int) x=0; return atomic_exchange_explicit(&x,1,memory_order_seq_cst); }
