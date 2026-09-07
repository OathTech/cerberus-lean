#include <stdatomic.h>
int main(void) { atomic_thread_fence(memory_order_seq_cst); return 0; }
