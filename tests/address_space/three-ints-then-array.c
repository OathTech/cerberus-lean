// tests/address_space — the tiny-address-space differential corpus (address-space-bound slice PART TWO, C3, 2026-09-17;
// charter lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md §2 C3). scripts/test_address_space.sh runs
// BOTH engines (the fork oracle with its FORK-ONLY --address-space-top N; cerberus-lean with the same flag) at tiny tops
// and compares the complete observations through the shared codec; the fork observations are pinned in expectations.txt.
// Every object (the driver's errno int, 4 bytes/align 4, comes first) is created at the descending cursor; a top too small
// for the next object kills out of memory (CerbMem.allocator_active_sound: an active allocation ends at or below the cursor).
// Footprint: errno 4 + a 4 + b 4 + c 4 + buf 16 = 32 bytes. top 64: Specified(6); top 32: buf exhausts (z = 16 - 16 = 0 is
// not a positive address); top 8: the second object exhausts. The charter's example program.
int main(void) {
  int a = 1;
  int b = 2;
  int c = 3;
  char buf[16];
  buf[0] = (char)(a + b + c);
  return buf[0];
}
