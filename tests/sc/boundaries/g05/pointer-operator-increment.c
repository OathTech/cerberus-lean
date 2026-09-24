#include <stdatomic.h>

int main(void) { int a[2]={3,4}; _Atomic(int *) p=a; int *old=p++; return *old*10+**(&p); }
