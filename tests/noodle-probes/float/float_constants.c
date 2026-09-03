/* Corner: floating constant syntax and types: hex floats, suffixes,
   denormals, sizeof (ISO C11 6.4.4.2). */
#include <stdio.h>
int main(void) {
  printf("%d ", (int)(0x1.8p1));                /* 3 */
  printf("%d ", (int)(0x10p-2));                /* 4 */
  printf("%d ", (int)sizeof(1.0f));             /* 4 */
  printf("%d ", (int)sizeof(1.0));              /* 8 */
  printf("%d ", (int)sizeof(1.0L));             /* gcc 16; Cerberus impl 8 (declared) */
  printf("%d ", 1e-320 > 0);                    /* 1 denormal */
  printf("%d ", 5e-324 > 0);                    /* 1 */
  printf("%d ", 2e-324 == 0);                   /* 1 rounds to zero */
  printf("%d%d ", (int)(1e2), (int)(.5e1));
  printf("%d\n", (int)(1.f + 1.e0 + 0x1p0));    /* 3 */
  return 0;
}
