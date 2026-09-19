#include <stdatomic.h>
int main(void) { int x=0; _Atomic(int) flag=0; int r=0; {-{ { x++; atomic_store_explicit(&flag,1,memory_order_seq_cst); } ||| { r=atomic_load_explicit(&flag,memory_order_seq_cst); if (r) x=7; } }-} return r; }
