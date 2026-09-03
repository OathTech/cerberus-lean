/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-02 (D2)).
   Origin: tests/noodle-probes/ptr/ptr_to_int_narrow_ub.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (UB024 with loc "other_location(Concrete)" vs the oracle's <7:11--7:17>); the fix
   commit re-records it MATCH (memFail MerrIntFromPtr loc, Z-02). The lane fails closed both ways. */
int main(void) {
  int x = 3;
  int *p = &x;
  int i = (int)p;
  return i & 1;
}
