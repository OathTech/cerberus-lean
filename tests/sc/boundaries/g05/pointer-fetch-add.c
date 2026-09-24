#include <stdatomic.h>

int main(void) { int a[2]={3,4}; _Atomic(int *) p=a; int *old=atomic_fetch_add(&p,1); return *old; }
