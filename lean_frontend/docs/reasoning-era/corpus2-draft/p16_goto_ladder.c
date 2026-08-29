/* P16 goto_ladder — general goto / multi-exit cleanup. MINIMUM-2 (uri.c E3:
 * 90 goto sites, 10 labels — the census's rank-9 idiom; the mem_error/done
 * cleanup shape in miniature). Fresh-written.
 * Families: general labels with MULTIPLE predecessors (fail has two in-edges;
 * unwind FALLS THROUGH into fail) — join-point reasoning at non-loop labels,
 * which loop back-edges (single-predecessor) never forced.
 * Theorem: forall a b, -2^31 <= a,b <= INT_MAX/2:
 *   outcomes = { Specified (if a < 0 then -1 else if b < 0 then -1 else a+b) },
 *   no UB.
 * BOUNDS (anti-brute-force, derived): upper INT_MAX/2 = 1073741823 so acc=a+b
 * cannot overflow on the success path; negative side full range (no sum is
 * computed there). Domain ~2^62 — enumeration inconceivable.
 * Dishonest-pass note (review C1, honest form): forces the general-label /
 * fall-through VOCABULARY (Erun to a non-loop parameterized label;
 * fall-through ENTRY into a save block — shapes the loop layer's back-edge
 * labels never produced). Join-ONCE composition is EXERCISED, not forced, at
 * 2 predecessors: a proof may legitimately step the 2-statement label body
 * once per path (cost proportional to structure — catechism §IV.1). The
 * amortization forcing arrives at uri.c scale, where `done` has ~40 in-edges
 * — this row is that idiom's miniature. */
int steps(int a, int b) {
  int acc = 0;
  if (a < 0) goto fail;
  acc = acc + a;
  if (b < 0) goto unwind;
  acc = acc + b;
  return acc;
unwind:
  acc = acc - a;
fail:
  return -1;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) {
  return (steps(3, 4) == 7 && steps(-1, 5) == -1 && steps(2, -2) == -1) ? 0 : 1;
}
