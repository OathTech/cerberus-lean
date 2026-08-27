/* P07 list_sum — heap linked-list traversal. Families: rep predicate (F11,
 * FORCED per review H2), struct fields (F10), pointer chain (F7), trip count
 * = list length (F2a). Derived (int_list shape) from deps/cn/tests/cn/
 * append.c (BSD-2).
 * H2 (review): the heap SKELETON is quantified — the encoding carries a
 * PERMUTATION pi of 0..n-1 and the prologue links arena[pi(i)] -> arena
 * [pi(i+1)], so which address links to which is quantified data (~n! shapes;
 * skeleton enumeration dies) and only an address-abstract rep predicate
 * prices proportionally to structure. wf m includes "pi is a permutation".
 * BOUNDS (anti-brute-force ruling): |l| <= ARENA = 2^20 nodes; heads full
 * int range under the SEMANTIC pre (every prefix sum in range).
 * PROVENANCE NOTE (review n4): the quantified skeleton lives within a
 * SINGLE arena object — pi permutes OFFSETS in one allocation, not
 * per-node allocations; per-allocation ownership is P13's row.
 * Theorem: forall l (payloads), pi (permutation), wf -> result = sum l. */
#define ARENA 1048576
static const int choices[] = {3, /*pi*/ 1, 2, 0, /*heads*/ 4, -1, 7}; /* SPLICED: [n; pi; heads] */
static const int expected_sum = 10;                                   /* SPLICED */
struct node { int head; struct node *tail; };
static struct node arena[ARENA];
int list_sum(const struct node *p) {
  int s = 0;
  while (p) { s = s + p->head; p = p->tail; }
  return s;
}
int main(void) {
  int n = choices[0]; struct node *hd = 0;
  for (int i = n - 1; i >= 0; i = i - 1) {          /* set_up_memory via pi */
    int slot = choices[1 + i];
    arena[slot].head = choices[1 + n + i]; arena[slot].tail = hd; hd = &arena[slot];
  }
  return list_sum(hd) == expected_sum ? 0 : 1;
}
