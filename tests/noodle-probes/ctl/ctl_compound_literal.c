/* Corner: compound literals: pointer to array literal, address of struct
   literal, sizeof of a literal, literal in a condition (ISO C11 6.5.2.5). */
#include <stdio.h>
struct S { int x; int y; };
int main(void) {
  int *p = (int[]){1, 2, 3};
  struct S *q = &(struct S){ .y = 5 };
  int sz = (int)sizeof((int[]){1, 2, 3});
  int k = ((struct S){.x = 4}).x;
  printf("%d %d %d %d %d\n", p[1], q->x, q->y, sz, k);   /* 2 0 5 12 4 */
  return 0;
}
