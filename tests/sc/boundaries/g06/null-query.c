#include <stdatomic.h>

int main(void) { return atomic_is_lock_free((_Atomic int*)0); }
