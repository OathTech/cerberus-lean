/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-06 (D5)).
   Origin: tests/noodle-probes/seam/seam_device_range_load.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (UB043 vs the oracle's Specified(3)); the fix
   commit re-records it MATCH (device_ranges mirror, Z-06). The lane fails closed both ways. */
int main(void) { int x = 5; int *p = (int*)0xABC; int y = *p; (void)y; return 3; }
