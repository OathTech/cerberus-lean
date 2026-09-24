#include <stdatomic.h>

int main(void) { int a[2]={3,4}; _Atomic(int *) p=a; int calls=0; atomic_fetch_add_explicit((++calls,&p),1,memory_order_seq_cst); return calls; }
