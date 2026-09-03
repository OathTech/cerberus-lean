/* Corner: long double VALUE semantics. Cerberus's impl declares
   sizeof(long double)=8 and evaluates long double as double, so
   1.0L/3.0L == 1.0/3.0 is 1 on both engines and 0 under gcc's 80-bit
   long double. Recorded as an impl divergence observer, not a bug. */
#include <stdio.h>
int main(void) {
  long double a = 1.0L / 3.0L;
  double b = 1.0 / 3.0;
  printf("%d ", a == b);                         /* gcc 0 / cerberus 1 */
  printf("%d ", (long double)0.1 == 0.1L);        /* gcc 0 / cerberus 1 */
  printf("%d ", (int)sizeof(long double));       /* gcc 16 / cerberus 8 */
  printf("%d\n", 1e308L * 10 > 1e308L);           /* gcc 1 (finite) / cerberus 1 (inf) */
  return 0;
}
