/* P06 arr_reverse — in-place reversal. Families: invariant over a PARTIALLY
 * TRANSFORMED array (F2a), writes at symbolic indices (F8), pointer
 * arithmetic (F7), memory as output via readback (F14). Fresh (classic).
 * BOUNDS (anti-brute-force ruling): n <= ARENA = 2^20, contents full int
 * range. Theorem: forall xs: final memory = reverse xs (mismatch-index
 * readback vs spliced expected[] = encode(reverse xs)). */
#define ARENA 1048576
static const int choices[] = {4, 1, 2, 3, 4}; /* SPLICED */
static const int expected[] = {4, 3, 2, 1};   /* SPLICED */
static int buf[ARENA];
void arr_reverse(int *a, int n) {
  int i = 0, j = n - 1;
  while (i < j) {
    int t = a[i]; a[i] = a[j]; a[j] = t;
    i = i + 1; j = j - 1;
  }
}
int main(void) {
  int n = choices[0];
  for (int i = 0; i < n; i = i + 1) buf[i] = choices[i + 1];
  arr_reverse(buf, n);
  for (int i = 0; i < n; i = i + 1) if (buf[i] != expected[i]) return 1 + i;
  return 0;
}
