// tests/address_space — the tiny-address-space differential corpus (address-space-bound slice PART TWO, C3, 2026-09-17;
// charter lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md §2 C3). scripts/test_address_space.sh runs
// BOTH engines (the fork oracle with its FORK-ONLY --address-space-top N; cerberus-lean with the same flag) at tiny tops
// and compares the complete observations through the shared codec; the fork observations are pinned in expectations.txt.
// Every object (the driver's errno int, 4 bytes/align 4, comes first) is created at the descending cursor; a top too small
// for the next object kills out of memory (CerbMem.allocator_active_sound: an active allocation ends at or below the cursor).
// Footprint: errno 4 + big 40 = 44 bytes. top 64: Specified(1) (big at 20); top 32: big exhausts (z = 28 - 40 < 0);
// top 8: the second object exhausts.
int main(void) {
  char big[40];
  big[0] = 1;
  return big[0];
}
