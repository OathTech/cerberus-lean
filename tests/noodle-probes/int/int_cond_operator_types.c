/* Corner: type of the conditional operator result under the usual
   arithmetic conversions (ISO C11 6.5.15p5) and integer promotions of
   the operands of ?: with narrow types. */
#include <stdio.h>
int main(void) {
  int t = 1;
  unsigned char uc = 1; short sh = 2;
  printf("%d ", (t ? -1 : 0u) > 0);              /* 1: unsigned */
  printf("%d ", (int)sizeof(t ? 'a' : 'b'));      /* 4 */
  printf("%d ", (int)sizeof(t ? uc : sh));        /* 4 */
  printf("%d ", (int)sizeof(t ? 1 : 1L));         /* 8 */
  printf("%d ", (t ? -1 : 0ul) > 0);             /* 1 */
  printf("%d ", (t ? -1 : (short)0) > 0);        /* 0: int */
  printf("%d ", (!t ? 1u : -2) < 0);             /* 0: unsigned */
  printf("%d\n", (int)sizeof(t ? 1.0f : 1));      /* 4 */
  return 0;
}
