/* P11 gcd_iter — TERMINATION BY MEASURE, not closed-form trip count.
 * Families: variant-based loop termination (F2c — the known while_inv gap),
 * branch (F1), % UB side condition (F12: b != 0 from the guard). Fresh
 * (Euclid). BOUNDS (anti-brute-force ruling): FULL TYPE RANGE — forall a b,
 * 0 < a <= INT_MAX, 0 <= b <= INT_MAX. No smaller constant exists in the
 * theorem. Theorem: result = gcd(a,b). */
int gcd(int a, int b) {
  while (b != 0) {
    int t = a % b;
    a = b;
    b = t;
  }
  return a;
}
int main(void) { return gcd(12, 18) == 6 ? 0 : 1; }
