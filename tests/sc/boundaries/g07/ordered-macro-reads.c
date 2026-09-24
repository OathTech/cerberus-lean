#include <stdatomic.h>
int main(void) { _Atomic int x=1,y=2; return (atomic_load(&x),atomic_load(&y)); }
