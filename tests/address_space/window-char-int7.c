// tests/address_space — the tiny-address-space differential corpus (address-space-bound slice PART TWO, C3, 2026-09-17;
// charter lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md §2 C3). scripts/test_address_space.sh runs
// BOTH engines (the fork oracle with its FORK-ONLY --address-space-top N; cerberus-lean with the same flag) at tiny tops
// and compares the complete observations through the shared codec; the fork observations are pinned in expectations.txt.
// Every object (the driver's errno int, 4 bytes/align 4, comes first) is created at the descending cursor; a top too small
// for the next object kills out of memory (CerbMem.allocator_active_sound: an active allocation ends at or below the cursor).
//
// THE DISCRIMINATOR (C4, pre-merge audit F2, 2026-09-18): the one case of this corpus on which the PRE-FIX allocator
// (pristine b9aeedcb4 impl_mem.ml:1254 — the truncating-division idiom over the Euclidean quomod, upstream-tray draft 44)
// and the FIXED allocator (remedy 1) DECIDE DIFFERENTLY. At top 32: errno (4, align 4) -> cursor 28; `c` (1, align 1)
// -> cursor 27; `a` (28 bytes, align 4): z = 27 - 28 = -1 — inside the defect window -align/2 < z < 0. Old: q = -1,
// m = 3, z' = z - (-m) = 2 -> ACTIVE at address 2 (misaligned, overlapping errno at 28..32). Fixed: z < 0 -> KILL. The
// program's only observable is the low byte of `a`'s address, so the pre-fix observation is Specified(2) and the fixed
// engines' is the out-of-memory Error; the old-body outcome is EXECUTED (not hand arithmetic) by the Lean probe
// lean_frontend/docs/2026-09-17_address-space-bound-part-two-evidence/c4-old-allocator-probe.lean (the pre-part-one
// CerbMem.allocator body at 4a23d98aa, run on the exact cursor). At top 64: errno -> 60, c -> 59, a: z = 31, m = 3,
// z' = 28 on BOTH bodies -> Specified(28). At top 8: errno -> 4, c -> 3, a: z = -25 -> both kill. The --selftest plant P1
// forges THIS case at top 32 to Specified(2) and must be rejected.
#include <stdint.h>
int main(void) {
  char c;
  int a[7];
  return (int)((uintptr_t)a & 0xff);
}
