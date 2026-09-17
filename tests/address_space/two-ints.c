// tests/address_space — the tiny-address-space differential corpus (address-space-bound slice PART TWO, C3, 2026-09-17;
// charter lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md §2 C3). scripts/test_address_space.sh runs
// BOTH engines (the fork oracle with its FORK-ONLY --address-space-top N; cerberus-lean with the same flag) at tiny tops
// and compares the complete observations through the shared codec; the fork observations are pinned in expectations.txt.
// Every object (the driver's errno int, 4 bytes/align 4, comes first) is created at the descending cursor; a top too small
// for the next object kills out of memory (CerbMem.allocator_active_sound: an active allocation ends at or below the cursor).
// Footprint: errno 4 + x 4 + y 4 = 12 bytes. top 64 / 32: Specified(12); top 8: the SECOND object (x) exhausts.
int main(void) {
  int x = 5;
  int y = 7;
  return x + y;
}
