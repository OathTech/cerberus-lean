/* Corner: the comma operator sequences left before right and yields the
   right operand's value; `i = (i++, i)` is defined (ISO C11 6.5.17). */
#include <stdio.h>
int main(void) {
  int a, b, i = 3, k = 0;
  int r = (a = 1, b = 2, a + b);
  i = (i++, i);                 /* 4 */
  for (int j = 0, m = 10; j < m; j++, m--) k++;   /* 5 */
  int c = (1, 2, 3);            /* 3 */
  printf("%d %d %d %d\n", r, i, k, c);
  return 0;
}
