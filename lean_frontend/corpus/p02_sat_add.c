/* P02 sat_add — saturating add. Families: arithmetic + overflow side conditions
 * (F12), branch at symbolic data (F1). Fresh-written (RefinedC-paper-style
 * arithmetic side-condition exemplar).
 * Theorem: forall a b in int range: result = if a+b > INT_MAX then INT_MAX
 * else if a+b < INT_MIN then INT_MIN else a+b — and NO UB (the guards must be
 * proven to prevent signed overflow; the reasoning must carry the C
 * arithmetic UB side conditions symbolically).
 * BONUS FORCING (review §4, recorded): the guards are UB-safe ONLY via &&
 * short-circuit — at a <= 0, `2147483647 - a` would itself overflow for
 * a = INT_MIN and is UNEVALUATED by sequencing (symmetrically the second
 * guard). The theorem therefore also forces sequenced-&& reasoning at
 * symbolic operands (matrix family F15). Keep exactly as written. */
int sat_add(int a, int b) {
  if (a > 0 && b > 2147483647 - a) return 2147483647;
  if (a < 0 && b < (-2147483647 - 1) - a) return -2147483647 - 1;
  return a + b;
}
int main(void) { return sat_add(2147483640, 10) == 2147483647 ? 0 : 1; }
