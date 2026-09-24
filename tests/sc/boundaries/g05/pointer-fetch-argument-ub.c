#include <stdatomic.h>
int zero(void) { return 0; }
int main(void) { int a[2]={3,4}; _Atomic(int *) p=a; atomic_fetch_add(&p,1/zero()); return 3; }
