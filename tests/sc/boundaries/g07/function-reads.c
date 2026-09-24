#include <stdatomic.h>
int get_atomic_value(_Atomic int *p) { return atomic_load(p); }
int main(void) { _Atomic int x=1,y=2; return get_atomic_value(&x)+get_atomic_value(&y); }
