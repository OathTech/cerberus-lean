/* P08 list_reverse — in-place pointer reversal, THE O'HEARN CLASSIC. Families:
 * rep predicates, two-partial-lists invariant (F11 hard form, FORCED per
 * review H2), struct fields (F10), pointer surgery (F7), memory out (F14).
 * Attribution: the canonical SL exemplar (Reynolds/O'Hearn); RefinedC
 * examples/reverse.c (BSD); text fresh for the int_list shape.
 * H2 (review): quantified link-order permutation, same as P07 — the summit
 * must be dodge-proof: with the skeleton quantified, the two-partial-lists
 * invariant is the only structure-priced route.
 * BOUNDS (anti-brute-force ruling): |l| <= ARENA = 2^20, heads full range.
 * PROVENANCE NOTE (review n4): the quantified skeleton lives within a
 * SINGLE arena object — pi permutes OFFSETS in one allocation, not
 * per-node allocations; per-allocation ownership is P13's row.
 * Theorem: forall l, pi, wf: final heap holds reverse l (readback walk). */
#define ARENA 1048576
static const int choices[] = {3, /*pi*/ 2, 0, 1, /*heads*/ 1, 2, 3}; /* SPLICED */
static const int expected[] = {3, 2, 1};                             /* SPLICED */
struct node { int head; struct node *tail; };
static struct node arena[ARENA];
struct node *list_reverse(struct node *p) {
  struct node *acc = 0;
  while (p) { struct node *t = p->tail; p->tail = acc; acc = p; p = t; }
  return acc;
}
int main(void) {
  int n = choices[0]; struct node *hd = 0;
  for (int i = n - 1; i >= 0; i = i - 1) {
    int slot = choices[1 + i];
    arena[slot].head = choices[1 + n + i]; arena[slot].tail = hd; hd = &arena[slot];
  }
  struct node *r = list_reverse(hd);
  for (int i = 0; i < n; i = i + 1) {               /* check_memory */
    if (!r || r->head != expected[i]) return 1 + i;
    r = r->tail;
  }
  return r ? 1 + n : 0;
}
