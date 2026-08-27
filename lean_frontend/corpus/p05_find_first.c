/* P05 find_first — sentinel/target scan with EARLY EXIT. Families: trip count
 * a function of quantified CONTENTS (F2b), early return (F4), symbolic index
 * (F8), branch (F1), multi-return (F13). Fresh-written (uri.c scan idiom).
 * BOUNDS (anti-brute-force ruling): n <= ARENA = 2^20; contents and target
 * full int range. Domain non-enumerable.
 * Theorem: forall xs (|xs| <= ARENA), x: result = LEAST i with xs[i] == x,
 * else n — the invariant must carry "no hit among indices < i". */
#define ARENA 1048576
static const int choices[] = {4, 7, 1, 9, 3};  /* SPLICED: [n; xs...] */
static const int target = 9;                   /* SPLICED */
static const int expected_idx = 2;             /* SPLICED = modelFn m (H5: least hit for [7,1,9,3], x=9 is index 2) */
static int buf[ARENA];
int find_first(const int *a, int n, int x) {
  for (int i = 0; i < n; i = i + 1) {
    if (a[i] == x) return i;
  }
  return n;
}
int main(void) {
  int n = choices[0];
  for (int i = 0; i < n; i = i + 1) buf[i] = choices[i + 1];
  return find_first(buf, n, target) == expected_idx ? 0 : 1;
}
