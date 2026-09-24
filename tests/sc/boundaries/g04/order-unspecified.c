#include <stdatomic.h>

int main(void) { atomic_int x=7; memory_order mo; memory_order *p=&mo; return atomic_load_explicit(&x,*p); }
