// 021: qsort (libc C smoothsort) on ints with duplicates and negatives,
// through a user comparator (a function pointer called from libc code).
#include <stdio.h>
#include <stdlib.h>
static int cmp(const void *a, const void *b) {
  int x = *(const int *)a, y = *(const int *)b;
  return (x > y) - (x < y);
}
int main(void) {
  int v[9] = {5, -3, 9, 0, 5, -3, 12, 1, -100};
  qsort(v, 9, sizeof v[0], cmp);
  int n = 0;
  for (int i = 0; i < 9; i++) n += printf("%d ", v[i]);
  return n + printf("\n");
}
