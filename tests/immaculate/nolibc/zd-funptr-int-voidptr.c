/* N1, second route: the same number through a stored void* (the read-back is
   a concrete address the funptrmap records as a function pointer). */
#include <stdint.h>
int f(void) { return 1; }
int main(void) { void *v = (void*)f; uintptr_t x = (uintptr_t)v; return (int)(x & 0xfff); }
