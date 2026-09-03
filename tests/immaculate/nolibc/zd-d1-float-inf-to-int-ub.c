/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-01 (D1)).
   Origin: tests/noodle-probes/float/float_inf_to_int_ub.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (UB017 with loc "unknown location" vs the oracle's <5:11--5:19>); the fix
   commit re-records it MATCH (std.core loc stamping, Z-01/Z-03). The lane fails closed both ways. */
int main(void) {
  double big = 1e300;
  int i = (int)big;
  return i & 1;
}
