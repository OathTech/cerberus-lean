#include <stdatomic.h>

int main(void) { int n=0; return atomic_is_lock_free((n++,1/0,(_Atomic int*)0)); }
