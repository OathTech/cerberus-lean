/* P10 gcd_rec — RECURSION with a DATA-DEPENDENT MEASURE (reviewer's definite
 * recommendation, review A3; the loop-variant/recursion-measure TWIN of P11,
 * sharing its model function at zero extra spec cost). Families: recursive
 * call consumed via its own contract (F6 — the induction hypothesis at
 * measure b' = a mod b < b), branch (F1), % UB side conditions (F12: b == 0
 * met by the base case BEFORE any %, INT_MIN/-1 excluded by the sign pres).
 * Fresh-written (Euclid).
 * BOUNDS (anti-brute-force ruling): FULL TYPE RANGE — forall a b,
 * 0 < a <= INT_MAX, 0 <= b <= INT_MAX (>= 2^32-point domain; no closed-form
 * depth — recursion depth is data-dependent, Fibonacci-worst-case; neither
 * enumeration nor call-tree unrolling is conceivable).
 * NOTE (P09 backstop): this program is the structural backstop for the
 * anti-inlining note on P09 — its data-dependent call depth cannot be
 * inlined away and its domain cannot be enumerated.
 * Theorem: forall a b in range: outcomes = {Specified gcd(a,b)}. */
int gcd_rec(int a, int b) {
  if (b == 0) return a;
  return gcd_rec(b, a % b);
}
int main(void) { return gcd_rec(12, 18) == 6 ? 0 : 1; }
