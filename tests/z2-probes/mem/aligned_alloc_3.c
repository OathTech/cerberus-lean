/* Z2 CONTROL: non-power-of-two alignment through the allocator arithmetic
   (impl_mem.ml:1247-1257 quomod/erem vs CerbMem.alignDown). libc mode. */
#include <stdlib.h>
#include <stdint.h>
int main(void) { void *p = aligned_alloc(3, 9); return (int)((uintptr_t)p % 3 == 0) + 10; }
