/* Corner: plain char is signed on the Cerberus/x86-64 impl; observe it
   through comparisons, hex escapes, conversions (ISO C11 6.2.5p15). */
#include <stdio.h>
int main(void) {
  char c = 200; char e = '\xff'; char *s = "\xff\x80";
  unsigned char uc = c;
  printf("%d ", c < 0);               /* 1 */
  printf("%d ", c);                   /* -56 */
  printf("%d ", e);                   /* -1 */
  printf("%d ", s[0] == e);           /* 1 */
  printf("%d ", s[1]);                /* -128 */
  printf("%u ", (unsigned)c);         /* 4294967240 */
  printf("%d ", uc);                  /* 200 */
  printf("%d ", (char)255 == 255);    /* 0 */
  printf("%d ", '\xff' < 0);          /* 1 */
  printf("%d\n", (unsigned char)'\xff' == 255); /* 1 */
  return 0;
}
