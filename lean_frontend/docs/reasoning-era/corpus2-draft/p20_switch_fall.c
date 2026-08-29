/* P20 switch_fall — switch WITH FALLTHROUGH (beyond P15's disjoint cases).
 * EXPLORATORY-2 (kernel lane: fallthrough switch is pervasive kernel style;
 * uri.c itself has NO switch — census §9 — so this is kernel-priority, not
 * uri.c-priority). Fresh-written.
 * Families (review C2, factual relabel): the switch ELABORATES to an
 * if-dispatch ladder + per-case save/run labels + a break label — NO
 * Ecase/PEcase node exists in this program's Core (verified by inspection).
 * G5 = the SWITCH-PROVENANCE dispatch shape: a stereotyped ladder + labeled
 * case bodies + fall-through at elaborated labels — G1 (general joins) at
 * the switch construct, from a different elaboration provenance than p16's
 * hand gotos. (The roadmap table's "switch → PEcase/Ecase chains" line is
 * inaccurate for this shape — flagged for table maintenance.)
 * Dishonest-pass note: the FALLTHROUGH is behaviorally forcing — a prover
 * that wrongly treats the arms as disjoint derives classify(2) = 1 and
 * fails against the spec's 2 -> 2. Join-once composition is exercised, not
 * forced (as p16).
 * Theorem: forall c in int range: outcomes = { Specified (switchModel c) },
 * no UB — switchModel: 2 -> 2, 1 -> 1, 0 -> 5, else -1.
 * BOUNDS: full int range. */
int classify(int c) {
  int k = 0;
  switch (c) {
    case 2: k = k + 1; /* FALLTHROUGH */
    case 1: k = k + 1; break;
    case 0: k = 5; break;
    default: k = -1; break;
  }
  return k;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) {
  return (classify(2) == 2 && classify(1) == 1 && classify(0) == 5 &&
          classify(7) == -1) ? 0 : 1;
}
