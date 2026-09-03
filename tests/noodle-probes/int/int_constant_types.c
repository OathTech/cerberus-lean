/* Corner: types of integer constants (ISO C11 6.4.4.1p5) observed through
   sizeof and signedness: 2147483648 is long; 0xFFFFFFFF is unsigned int;
   -0x80000000 is the unsigned int 2147483648. */
#include <stdio.h>
int main(void) {
  printf("%d ", (int)sizeof(2147483648));   /* 8 */
  printf("%d ", (int)sizeof(0xFFFFFFFF));   /* 4 */
  printf("%d ", (int)sizeof(4294967295));   /* 8 */
  printf("%d ", (int)sizeof('a'));          /* 4 */
  printf("%d ", (int)sizeof(2147483647));   /* 4 */
  printf("%d ", (int)sizeof(0x7FFFFFFF+1u));/* 4 */
  printf("%d ", -2147483648 < 0);           /* 1: long */
  printf("%d ", 0xFFFFFFFF < 0);            /* 0 */
  printf("%d ", -0x80000000 < 0);           /* 0: unsigned int */
  printf("%d ", 0x80000000 == 2147483648);  /* 1 */
  printf("%d%d ", (int)sizeof(1L), (int)sizeof(1LL));
  printf("%d\n", (int)sizeof(077777777777));/* 8: octal 8589934591 */
  return 0;
}
