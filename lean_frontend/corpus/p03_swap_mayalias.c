/* P03 swap — pointers + BOTH ALIAS ARMS IN ONE THEOREM (review H6 relabel:
 * the alias selector resolves before swap runs, so this forces the disjoint
 * two-cell case AND the p=q collapse case discharged from ONE both-arms
 * spec — NOT unresolved symbolic may-alias, which is deferred to the first
 * memmove-shaped target). Families: pointer deref (F7), frame/alias arms
 * (F9, relabeled), memory in/out (F14). Derived (shape) from deps/cn/tests/
 * cn/swap_pair.c (BSD-2) — two independent pointers so both arms arise.
 * NOTE: swap is proved ONCE against a spec covering both arms (p=q-
 * conditional post); proving the arms by separate per-arm inlining is not
 * the intent. alias in {0,1} is structural case vocabulary, not a data
 * domain (a,b are full-range).
 * Theorem (two-case post over quantified init memory a,b and alias choice):
 *   disjoint: mem'[p]=b, mem'[q]=a;  aliased (p=q): mem'[p]=a (self-swap id).
 * The harness prologue stores quantified init (a,b) into one or two cells per
 * the quantified alias selector; readback returns mismatch-index vs expected. */
void swap(int *p, int *q) {
  int tmp = *p;
  *p = *q;
  *q = tmp;
}
int harness(int a, int b, int alias) {
  int x = a, y = b;              /* set_up_memory(init) */
  int *q = alias ? &x : &y;
  swap(&x, q);
  /* check_memory: expected computed pure-side per (a,b,alias) */
  if (alias) return (x == a) ? 0 : 1;
  return (x == b && y == a) ? 0 : (x == b ? 2 : 1);
}
int main(void) { return harness(1, 5, 0); }
