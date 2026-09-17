// tests/address_space — the tiny-address-space differential corpus (address-space-bound slice PART TWO, C3, 2026-09-17;
// charter lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md §2 C3). scripts/test_address_space.sh runs
// BOTH engines (the fork oracle with its FORK-ONLY --address-space-top N; cerberus-lean with the same flag) at tiny tops
// and compares the complete observations through the shared codec; the fork observations are pinned in expectations.txt.
// Every object (the driver's errno int, 4 bytes/align 4, comes first) is created at the descending cursor; a top too small
// for the next object kills out of memory (CerbMem.allocator_active_sound: an active allocation ends at or below the cursor).
// The heap path (--nolibc malloc = the Core stdlib's malloc_proxy, which creates an 8-byte argument temporary before
// alloc): errno 4 + p 8 (the pointer object) + the temporary 8 + the 8-byte heap object. top 64: Specified(2); top 32:
// exhausted inside the malloc path; top 8: the second object exhausts.
#include <stdlib.h>
int main(void) {
  char *p = malloc(8);
  if (p == NULL) return 3;
  p[0] = 2;
  return p[0];
}
