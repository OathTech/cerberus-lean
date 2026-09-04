/* zero-discrepancy Z2 pin (2026-09-03; audit rows Z2-M-03/Z2-M-04, tests/z2-probes/mem/malloc_oom_msg.c;
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Four malloc(1ULL<<46) exhaust the 2^48 address
   space: the oracle's allocator fails `MerrOther "Concrete.allocator: failed (out of memory)"`
   (impl_mem.ml:1254-1255). Before Z2 the Lean side could not be run at all — allocateRegion eagerly
   materialised 2^46 unspecified bytes per region (the Z-30 malloc OOM class) and its message was
   `MerrOther "out of memory"`; after Z2-M-04 (no bytemap write, = impl_mem.ml:1420-1435) and Z2-M-03
   (text) both engines answer the same Error line. Pinned MATCH. libc mode. */
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
