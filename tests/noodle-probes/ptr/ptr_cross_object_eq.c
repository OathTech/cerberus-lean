/* Corner: EQUALITY of pointers to distinct objects is defined (0)
   (ISO C11 6.5.9p6); no relational operator is used. */
#include <stdio.h>
int g1, g2;
int main(void) {
  int l1, l2;
  int *p = &l1, *q = &l2;
  printf("%d %d %d %d\n", &g1 == &g2, p == q, p == &l1, (void*)&g1 == (void*)&l1);
  return 0;
}
