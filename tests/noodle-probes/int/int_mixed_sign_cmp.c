/* Corner: usual arithmetic conversions at every rank boundary for
   relational operators with mixed signedness (ISO C11 6.3.1.8). */
#include <stdio.h>
int main(void) {
  int a = -1; unsigned u = 1; long l = -1; unsigned long ul = 1;
  long long ll = -1; short s = -1; unsigned short us = 1;
  signed char sc = -1; unsigned char uc = 1;
  printf("%d", a < u);          /* 0: -1 -> UINT_MAX */
  printf("%d", l < u);          /* 1: unsigned int -> long (LP64) */
  printf("%d", a < ul);         /* 0 */
  printf("%d", ll < ul);        /* 0: long long cannot hold all unsigned long -> both unsigned long long */
  printf("%d", s < us);         /* 1: both promote to int */
  printf("%d", sc < uc);        /* 1 */
  printf("%d", a == 4294967295u); /* 1 */
  printf("%d", (unsigned)a > 0); /* 1 */
  printf("%d", -1 < 0u);        /* 0 */
  printf("%d", (long)-1 < 0u);  /* 1 */
  printf("\n");
  return 0;
}
