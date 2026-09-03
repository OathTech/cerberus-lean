/* Corner: unary minus / complement on unsigned and on promoted narrow
   unsigned operands (ISO C11 6.5.3.3, 6.3.1.1). */
#include <stdio.h>
int main(void) {
  unsigned u = 1; unsigned char uc = 1; unsigned short us = 1;
  unsigned long ul = 1;
  printf("%u ", -u);          /* 4294967295 */
  printf("%d ", -uc);         /* -1 : promoted to int */
  printf("%d ", -us);         /* -1 */
  printf("%lu ", -ul);        /* 18446744073709551615 */
  printf("%u ", -0u);         /* 0 */
  printf("%u ", ~0u);         /* 4294967295 */
  printf("%d ", ~uc);         /* -2 */
  printf("%d ", !uc);         /* 0 */
  printf("%d ", -(unsigned char)255); /* -255 */
  printf("%u\n", (unsigned)-(unsigned short)65535); /* 4294901761 */
  return 0;
}
