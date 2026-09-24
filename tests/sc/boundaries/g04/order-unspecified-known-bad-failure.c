#include <stdatomic.h>

int main(void) { atomic_int x=7; memory_order mo; memory_order *p=&mo; int expected=7; return atomic_compare_exchange_strong_explicit(&x,&expected,9,*p,memory_order_release); }
