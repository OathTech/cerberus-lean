/* P19 static_tick — mutable global/static state across calls. MINIMUM-2
 * (corpus-1 Q2 deferral now hunted: "pKVM lane" — kernel code is full of
 * module-static state; uri.c's cleanup-flag field is the same family).
 * Fresh-written.
 * Families: a static cell written by a callee and threaded across TWO calls —
 * the callee's contract must speak about the GLOBAL footprint (calls += 1),
 * new contract vocabulary (globals in pre/post). Depends on the V4 call rule.
 * Theorem: forall x, x <= INT_MAX-2: outcomes = { Specified 1 }, no UB
 *   (b - a = (x+2) - (x+1) = 1 regardless of x and of the initial counter 0).
 * ANTI-INLINING NOTE (the settled P09 situation — note, not gate, per the
 * operator's corpus-1 ruling): inlining both tick calls to dodge the
 * contract is not a legitimate technique for this row; the deliverable is
 * the callee contract carrying the STATIC CELL (calls ↦ c pre / c+1 post)
 * consumed twice. Protocol sliver (review C5): the elaboration emits a real
 * `glob calls` section — the harness protocol needs glob-INIT stepping +
 * globals in EnvHyp before contracts mention them (priced S on top of V4).
 * BOUNDS (derived): x+2 <= INT_MAX; lower full range. Domain ~2^32. */
static int calls = 0;
static int tick(int x) { calls = calls + 1; return x + calls; }
int drive(int x) {
  int a = tick(x);
  int b = tick(x);
  return b - a;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) { return (drive(10) == 1) ? 0 : 1; }
