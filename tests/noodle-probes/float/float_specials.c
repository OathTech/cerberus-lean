/* Corner: infinities and NaN produced by overflow and inf-inf (NOT by
   division by zero, which Cerberus reports as UB045a): comparisons, -0.0
   (ISO C11 Annex F / 6.5.8, 6.5.9). */
#include <stdio.h>
int main(void) {
  double big = 1e308;
  double inf = big * 10;
  double nan = inf - inf;
  double nz = -0.0;
  printf("%d ", inf > big);          /* 1 */
  printf("%d ", nan != nan);         /* 1 */
  printf("%d ", nan == nan);         /* 0 */
  printf("%d ", nan < 1.0);          /* 0 */
  printf("%d ", !(nan >= 1.0));      /* 1 */
  printf("%d ", nz == 0.0);          /* 1 */
  printf("%d ", nz < 0.0);           /* 0 */
  printf("%d ", -inf < -big);        /* 1 */
  printf("%d ", inf == inf + 1);     /* 1 */
  printf("%d\n", (int)(nz * -1 == 0.0)); /* 1 */
  return 0;
}
