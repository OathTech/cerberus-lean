/* Corner: sizeof does not evaluate its (non-VLA) operand; sizeof precedence
   and unary-expression operand (ISO C11 6.5.3.4). */
#include <stdio.h>
int main(void) {
  int i = 1;
  int a = (int)sizeof(i++);      /* 4, i still 1 */
  int b = (int)sizeof 1 + 1;     /* 5 */
  int c = (int)sizeof(char) - 1; /* 0 */
  int d = (int)sizeof (int) * 2; /* 8 */
  printf("%d %d %d %d %d\n", a, i, b, c, d);
  return 0;
}
