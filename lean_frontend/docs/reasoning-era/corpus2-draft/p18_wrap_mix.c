/* P18 wrap_mix — unsigned wraparound arithmetic (the defined-overflow ring).
 * MINIMUM-2 (corpus-1 Q2 deferral now hunted: "natural at pKVM/WireGuard
 * hash targets" — this IS the multiplicative-hash shape those targets use).
 * Fresh-written (Knuth multiplicative constant).
 * Families: unsigned multiply/xor/shift/add all WRAPPING (defined mod 2^32) —
 * the UB machinery must NOT fire anywhere (a deliberate over-fire shakeout:
 * every op here is defined despite "overflowing").
 * Theorem: forall a b in uint range: outcomes = { Specified (mixModel a b) },
 * no UB — where mixModel is the same ops over Nat mod 2^32.
 * WIDTH NOTE (review C5): this row is 32-bit; WireGuard's siphash is u64 —
 * the eval-law class this row lands is expected WIDTH-GENERIC (mod-2^w ring,
 * w a parameter), so the kernel justification carries; a u64 row is flagged
 * for the coverage table's maintenance, not drafted here.
 * BOUNDS: full unsigned range both arguments (~2^64 domain). */
unsigned int mix(unsigned int a, unsigned int b) {
  unsigned int h = a * 2654435761u;
  h = h ^ b;
  h = h + (h << 3);
  return h;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) { return (mix(1u, 2u) == 2415085387u) ? 0 : 1; }
