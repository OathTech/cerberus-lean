#include <stdatomic.h>
int zero(void) { return 0; }
int main(void) { atomic_int x=7; memory_order mo; memory_order *p=&mo; return atomic_exchange_explicit(&x,1/zero(),*p); }
