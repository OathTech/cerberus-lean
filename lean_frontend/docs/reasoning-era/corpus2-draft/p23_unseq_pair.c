/* P23 unseq_pair — TRUE unsequenced evaluation, proof-side ND. EXPLORATORY-2
 * (cmm-adjacent: the first row whose theorem quantifies over the runner's
 * genuine interleavings; nothing in uri.c forces it — census-honest).
 * Fresh-written.
 * Families: Eunseq with side effects on DISTINCT objects (defined by C11 —
 * no UB): the two inner assignments may run in either order; the outcome SET
 * must be proved a SINGLETON across ALL orders — the first proof-side
 * nondeterminism row (End/Eunseq branching rules; today the runner owns
 * orders semantics-side only).
 * Theorem: forall x, |x| <= (INT_MAX-6)/4: outcomes = { Specified (4x+6) },
 * no UB — s = (x+1)+(x+2) = 2x+3 under EITHER order; result s+a+b = 4x+6.
 * Dishonest-pass note (review-verified at Core): the two stores sit inside
 * the two arms of a genuine `unseq` node (weak-sequenced within arms,
 * unsequenced across) — the outcome-SET claim ranges over the runner's real
 * interleavings; with 2 orders, the minimal machinery is an unseq-split
 * rule + a same-outcome join, and the 2-case order enumeration is
 * STRUCTURAL (the program's own branch count), not the forbidden kind.
 * BOUNDS (derived): 4x+6 in int range -> |x| <= 536870910; ~2^30 domain,
 * non-enumerable. */
int pair(int x) {
  int a = 0;
  int b = 0;
  int s = (a = x + 1) + (b = x + 2);
  return s + a + b;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) { return (pair(1) == 10) ? 0 : 1; }
