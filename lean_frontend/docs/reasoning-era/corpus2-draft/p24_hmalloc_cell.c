/* P24 h_malloc_cell — DRAFT, POST-REVIEW ADDITION (awaiting the reviewer's
 * DELTA PASS; not part of the reviewed 8). P13's failable sibling, per the
 * operator's malloc-null / F1-rescope ruling [USER 2026-08-29]: allocation
 * FAILURE enters as CHOICE-STREAM DATA (the arc-15 const-embedding pattern
 * — no semantic ND added), so BOTH arms are live as quantified data and
 * P13's design-dependent F1 cell is realized un-conditionally here.
 * Families: F11 (ownership birth/death + leak on both arms), F1 (the null
 * branch, live by data), G-contract: the h_malloc wrapper's NULL ∨ POINTS-TO
 * DISJUNCTION contract — {emp} h_malloc(n) {r. (r = NULL ∧ fail-choice) ∨
 * (r ↦ n uninit bytes)} — the classic failable-malloc spec (VST/CN-style
 * malloc contract lineage), consumed by cell under a case-split on the
 * disjunction.
 * CONTRACTS-PRIMACY acceptance framing [USER 2026-08-29]: the row's
 * DELIVERABLE is that ∀-context contract pair (h_malloc's disjunction +
 * cell's spec over quantified ambient state); the harness theorem below is
 * the DERIVED COROLLARY.
 * Theorem (corollary form): forall v <= INT_MAX-1, forall c in {0,1} (the
 * spliced failure choice — case STRUCTURE as data, the P03-alias pattern):
 * outcomes = { Specified (c = 1 -> SENTINEL; else v+1) }, no UB, no leak on
 * either arm.
 * BOUNDS (derived): v+1 <= INT_MAX; SENTINEL = INT_MIN is a fixed SPEC
 * code (as P13), not a domain bound; c is structural. Depends on V5
 * (Alloc0/Kill-dynamic) + the alloc-ND evaluation's design decision for
 * P13 — this row is that decision's failable face made choice-determined. */
#include <stdlib.h>
static int fail_choice = 0; /* SPLICED: choice-stream slot — failure as DATA */
static void *h_malloc(unsigned long n) {
  if (fail_choice) return 0;
  return malloc(n);
}
int cell(int v) {
  int *p = (int *)h_malloc(sizeof(int));
  int r;
  if (p == 0) return (-2147483647 - 1); /* SENTINEL */
  *p = v;
  r = *p + 1;
  free(p);
  return r;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) { return (cell(41) == 42) ? 0 : 1; }
