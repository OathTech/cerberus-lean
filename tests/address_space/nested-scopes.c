// tests/address_space — the tiny-address-space differential corpus (address-space-bound slice PART TWO, C3, 2026-09-17;
// charter lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md §2 C3). scripts/test_address_space.sh runs
// BOTH engines (the fork oracle with its FORK-ONLY --address-space-top N; cerberus-lean with the same flag) at tiny tops
// and compares the complete observations through the shared codec; the fork observations are pinned in expectations.txt.
// Every object (the driver's errno int, 4 bytes/align 4, comes first) is created at the descending cursor; a top too small
// for the next object kills out of memory (CerbMem.allocator_active_sound: an active allocation ends at or below the cursor).
// Footprint: errno 4 + r 4 + t 4 + u 4 = 16 bytes (a kill frees an object but the cursor only descends, so block-scoped
// objects still consume address space). top 64 / 32: Specified(9); top 8: the second object exhausts.
int main(void) {
  int r = 0;
  { int t = 4; r = t; }
  { int u = 5; r += u; }
  return r;
}
