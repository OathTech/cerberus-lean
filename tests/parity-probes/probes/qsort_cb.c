#include <stdlib.h>
static int cmp(const void *a, const void *b) {
  return *(const int*)a - *(const int*)b;
}
int main(void) {
  int v[5] = {4, 1, 5, 2, 3};
  qsort(v, 5, sizeof(int), cmp);
  return v[0] + 10*v[4] + (v[1]==2) + (v[2]==3);  /* 1+50+1+1 = 53 */
}
