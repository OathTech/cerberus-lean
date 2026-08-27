/* P04 arr_sum — array traversal at symbolic contents AND length. Families:
 * loop invariant with quantified-n trip count (F2a), array at symbolic index
 * (F8), pointer walk (F7), overflow precondition (F12), input memory (F14).
 * Derived (shape) from CN array tests (BSD-2); fresh text.
 * BOUNDS (anti-brute-force ruling): n <= ARENA = 2^20 (object-model scale —
 * the mkHarness splice emits an exact-size array per m; ARENA is the sample
 * arena's capacity, not a theorem-relevant constant); elements bounded only
 * by the SEMANTIC no-overflow pre: every prefix sum in int range (the
 * invariant carries it). Domain ~ 2^20 lengths x full int range per element
 * — enumeration inconceivable.
 * Theorem: forall xs, wf xs -> outcome = {Specified 0}. */
#define ARENA 1048576
static const int choices[] = {3, 5, -2, 9}; /* SPLICED per m: [n; xs...] exact-size */
static const int expected_sum = 12;         /* SPLICED = modelFn m */
static int buf[ARENA];
int arr_sum(const int *a, int n) {
  int s = 0;
  for (int i = 0; i < n; i = i + 1) s = s + a[i];
  return s;
}
int main(void) {
  int n = choices[0];
  for (int i = 0; i < n; i = i + 1) buf[i] = choices[i + 1];
  return arr_sum(buf, n) == expected_sum ? 0 : 1;
}
