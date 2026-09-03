/* Corner: usual arithmetic conversions between integer and floating operands
   (ISO C11 6.3.1.8p1): int/double, int/float, unsigned/float, long long/float. */
#include <stdio.h>
int main(void) {
  int i = 7; unsigned u = 4294967295u; long long ll = 9007199254740993LL;
  float f = 0.5f;
  printf("%d ", (int)(i / 2 * 2.0));       /* 6 */
  printf("%d ", (int)(i / 2.0 * 2));       /* 7 */
  printf("%d ", (int)(1 / 2.0 + 1 / 2));   /* 0 */
  printf("%d ", u + f == 4294967296.0f);   /* 1: u -> float rounds */
  printf("%d ", ll + 0.0 == 9007199254740992.0); /* 1 */
  printf("%d ", (int)(5.5 - (int)5.5) * 2);       /* 0: (int)(0.5)*2 */
  printf("%d ", (int)((5.5 - (int)5.5) * 2));     /* 1 */
  printf("%d ", -7 / 2.0 < -3);                    /* 1 */
  printf("%d\n", (int)(-7 / 2.0));                 /* -3 */
  return 0;
}
