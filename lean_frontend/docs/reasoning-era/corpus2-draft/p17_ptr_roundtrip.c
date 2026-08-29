/* P17 ptr_roundtrip — ptr <-> int casts (PNVI). MINIMUM-2 (kernel-demanded:
 * pKVM page/address arithmetic; RefinedC ships the family as
 * examples/intptr.c, BSD — shape lineage, text fresh).
 * Families: pointer-to-integer cast (provenance exposure), integer-to-pointer
 * cast (provenance recovery under PNVI-ae-udi), deref through the recovered
 * pointer. The theorem does NOT depend on address VALUES (no address in the
 * spec) — it forces the CAST semantics, not address observability.
 * EASY-FACE HONESTY (review C4): the recovery step is UNAMBIGUOUS BY
 * CONSTRUCTION — exactly one live, exposed allocation contains the address.
 * This row forces the cast-memop vocabulary (IntFromPtr / PtrFromInt /
 * PtrValidForDeref, all Core-verified on the only path) but only the EASY
 * face of PNVI: multiple exposed candidates, one-past pointers,
 * dead-allocation recovery, and udi disambiguation ALL stay deferred (the
 * recorded list), alongside the address-arithmetic rows. LP64 note: unsigned
 * long is 8 bytes in the house model — no truncation on the roundtrip.
 * Theorem: forall v in int range: outcomes = { Specified v }, no UB.
 * BOUNDS: full int range. */
int roundtrip(int v) {
  int x = v;
  int *p = &x;
  unsigned long u = (unsigned long)p;
  int *q = (int *)u;
  return *q;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) { return (roundtrip(42) == 42 && roundtrip(-7) == -7) ? 0 : 1; }
