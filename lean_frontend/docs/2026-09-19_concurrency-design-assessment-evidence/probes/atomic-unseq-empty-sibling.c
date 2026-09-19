#include <stdatomic.h>
int main(void){_Atomic(int)x=0;int r;{-{ r=atomic_load_explicit(&x,memory_order_seq_cst)+(atomic_store_explicit(&x,1,memory_order_seq_cst),0); ||| ; }-}; return r;}
