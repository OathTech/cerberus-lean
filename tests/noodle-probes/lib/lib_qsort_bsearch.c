/* Corner: qsort with a comparator returning a-b on small ints, stability
   not required; bsearch hit and miss (ISO C11 7.22.5). */
#include <stdlib.h>
#include <stdio.h>
int cmp(const void *a, const void *b) { return *(const int*)a - *(const int*)b; }
int main(void) {
  int v[7] = {5, -3, 9, 0, 2, -3, 7};
  qsort(v, 7, sizeof v[0], cmp);
  int key = 7, miss = 4;
  int *hit = bsearch(&key, v, 7, sizeof v[0], cmp);
  int *no = bsearch(&miss, v, 7, sizeof v[0], cmp);
  printf("%d %d %d %d %d %d %d | %d %d\n", v[0], v[1], v[2], v[3], v[4], v[5], v[6], hit ? (int)(hit - v) : -1, no == 0);
  return 0;
}
