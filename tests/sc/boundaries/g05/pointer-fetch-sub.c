#include <stdatomic.h>

int main(void) { int a[2]={3,4}; _Atomic(int *) p=a; atomic_fetch_sub(&p,1); return 3; }
