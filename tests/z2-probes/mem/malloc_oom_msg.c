/* Z2 probe (allocator out-of-memory text): impl_mem.ml:1255 MerrOther
   "Concrete.allocator: failed (out of memory)" vs CerbMem.lean allocateRegion
   MerrOther "out of memory" (an Error verdict line, text differs). Also the
   oracle's allocate_region writes NO bytemap bytes (impl_mem.ml:1420-1435)
   while CerbMem.allocateRegion materialises `List.replicate size` unspecified
   bytes — the Z-30 OOM shape; Lean is NOT run on this probe (--nolean). libc. */
#include <stdlib.h>
int main(void) {
  void *a = malloc(1ULL << 46); void *b = malloc(1ULL << 46);
  void *c = malloc(1ULL << 46); void *d = malloc(1ULL << 46);
  return (a != 0) + (b != 0) + (c != 0) + (d != 0);
}
