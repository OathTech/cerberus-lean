/* Corner: float arithmetic must be single precision, observable without
   printf-%f via integer conversions and equalities (ISO C11 5.2.4.2.2,
   6.3.1.8 with FLT_EVAL_METHOD 0). */
#include <stdio.h>
int main(void) {
  float a = 0.1f, b = 0.2f, c = 0.3f;
  float third = 1.0f / 3.0f;
  float big = 16777217;
  printf("%d ", a + b == c);                      /* 1 in float; 0 in double */
  printf("%d ", (int)((float)0.1 * 1e9));         /* 100000001 (float 0.1 promoted) */
  printf("%d ", (double)third * 3 == 1.0);        /* 0 */
  printf("%d ", (int)big);                        /* 16777216 */
  printf("%d ", (double)(float)0.1 == 0.1);       /* 0 */
  printf("%d ", 0.1 + 0.2 == 0.3);                /* 0 */
  printf("%d ", (float)1e10 == 1e10);             /* 1 exact */
  printf("%d\n", (int)((1.0f + 1e-8f) == 1.0f));  /* 1 */
  return 0;
}
