/* P13 cell_alloc — heap ALLOCATION + OWNERSHIP + the leak conjunct. Families:
 * malloc/free ownership (F11), null branch (F1), pointer deref (F7).
 * Fresh-written (RefinedC talk_demo_alloc shape, BSD — text fresh).
 * BOUNDS (anti-brute-force ruling, derived): v <= INT_MAX - 1 = 2147483646
 * (sole hazard v+1; otherwise full range). SENTINEL = INT_MIN is a fixed
 * SPEC code, not a domain bound.
 * Theorem (CORE, unconditional): forall v <= INT_MAX-1: on the success
 * outcome result = v+1, ownership birth at malloc / death at free, AND the
 * leak conjunct (final allocation map empty on every path).
 * DESIGN-DEPENDENT clause (review H8 — the standing SL-alloc design-
 * evaluation gate is NOT pre-decided by this corpus): IF the evaluated
 * memory model makes malloc failable, outcomes = {Specified (v+1),
 * Specified SENTINEL} and the null branch is live (F1); if infallible,
 * outcomes = {Specified (v+1)} and the null branch is statically dead
 * (F1 cell withdrawn). The subseteq connective resolves to = with that
 * design decision. */
#define SENTINEL (-2147483647 - 1)
extern void *malloc(unsigned long n);
extern void free(void *p);
int roundtrip(int v) {
  int *p = (int *)malloc(sizeof(int));
  if (!p) return SENTINEL;
  *p = v;
  int r = *p + 1;
  free(p);
  return r;
}
int main(void) { return roundtrip(41) == 42 ? 0 : 1; }
