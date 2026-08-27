/* P10-ALT rsum_rec — ALTERNATE P10 CANDIDATE (retained, NOT the recommended
 * frozen row; the operator's one-time sign-off decides gcd_rec (RECOMMENDED,
 * review A3) vs this). Honest remark (review A3/H3 boundary): the domain is
 * the type-derived maximum 65535 = 2^16 points (the gray-zone bound) and the
 * postcondition IS its closed form. Warm-up virtue for the infra plan: the
 * T5-familiar model isolates the NEW call machinery — B4's first worked
 * warm-up instance even if not frozen.
 * Original header: RECURSION with a decreasing measure and a TYPE-DERIVED
 * domain (replaces factorial, whose honest domain 0..12 is enumerable —
 * anti-brute-force ruling). Families: recursive call via its own contract
 * (F6 — callee spec = induction hypothesis), overflow side conditions (F12),
 * branch (F1). Fresh-written.
 * DOMAIN DERIVATION (inline per the ruling): rsum(n) = n(n+1)/2 must fit
 * int: n(n+1)/2 <= 2147483647  <=>  n <= 65535
 * (65535*65536/2 = 2147450880 <= INT_MAX; 65536*65537/2 = 2147516416 > INT_MAX).
 * 2^16 values x recursion depth up to 65535 — not an enumeration target,
 * and the bound is the largest the type admits.
 * Theorem: forall n, 0 <= n <= 65535: result = n*(n+1)/2. */
int rsum(int n) {
  if (n <= 0) return 0;
  return n + rsum(n - 1);
}
int main(void) { return rsum(5) == 15 ? 0 : 1; }
