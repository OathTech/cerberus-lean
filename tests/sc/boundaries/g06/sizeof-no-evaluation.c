#include <stdatomic.h>

int main(void) { _Atomic int x[2]={1,2}; _Atomic int *p=x; return sizeof(atomic_is_lock_free(p++))==sizeof(_Bool) && p==x; }
