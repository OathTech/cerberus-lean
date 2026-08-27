/* P14 count_pairs — NESTED LOOPS. Families: nested invariants (F3), two
 * symbolic indices (F8), quadratic trip counts (F2a), arithmetic bound (F12).
 * Fresh-written.
 * BOUNDS (anti-brute-force ruling, derived inline): the count c is at most
 * n(n-1)/2, which must fit int: n <= 65536 (65536*65535/2 = 2147450880 <=
 * INT_MAX). ARENA = 65536 — the largest the RESULT TYPE admits, documented;
 * contents full int range. Domain non-enumerable.
 * Theorem: forall xs (|xs| <= 65536): result = #{(i,j) | i<j, xs[i]=xs[j]}. */
#define ARENA 65536
static const int choices[] = {4, 2, 7, 2, 2}; /* SPLICED */
static const int expected_cnt = 3;            /* SPLICED */
static int buf[ARENA];
int count_pairs(const int *a, int n) {
  int c = 0;
  for (int i = 0; i < n; i = i + 1)
    for (int j = i + 1; j < n; j = j + 1)
      if (a[i] == a[j]) c = c + 1;
  return c;
}
int main(void) {
  int n = choices[0];
  for (int i = 0; i < n; i = i + 1) buf[i] = choices[i + 1];
  return count_pairs(buf, n) == expected_cnt ? 0 : 1;
}
