#include <stdatomic.h>

int main(void) { _Atomic int x=7; if(0) atomic_is_lock_free(&x); return 9; }
