#include <stdatomic.h>

int main(void) { int a[2]={3,4}; _Atomic(int *) p=a; if (0) atomic_fetch_add(&p,1); return *p; }
