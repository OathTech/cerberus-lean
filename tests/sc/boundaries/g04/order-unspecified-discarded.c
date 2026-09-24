#include <stdatomic.h>

int main(void) { atomic_int x=7; memory_order mo; memory_order *p=&mo; atomic_load_explicit(&x,*p); return 3; }
