#include <stdatomic.h>

int main(void) { int a[2]={3,4}; _Atomic(int *) p=a; atomic_fetch_add_explicit(&p,1,memory_order_relaxed); return 3; }
