/* Corner: one-past-the-end pointer: relational/equality comparisons and
   differences are defined (ISO C11 6.5.6p8, 6.5.8p5, 6.5.9p6). */
#include <stdio.h>
int main(void) {
  int a[4] = {1,2,3,4};
  int *p = a + 4;
  printf("%d %d %d %d %d %d\n", p > a, (int)(p - a), p == &a[4], (p - 1) == &a[3], *(p - 1), p >= &a[3]);
  return 0;
}
