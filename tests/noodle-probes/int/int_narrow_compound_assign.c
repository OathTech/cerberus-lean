/* Corner: compound assignment / ++ on narrow types: the arithmetic happens
   in int (no overflow), then the impl-defined conversion back to the narrow
   type wraps (ISO C11 6.5.16.2, 6.3.1.3). NOT undefined behaviour. */
#include <stdio.h>
int main(void) {
  unsigned char c = 255; c += 1;         /* 0 */
  unsigned char d = 1;   d <<= 8;        /* 0 */
  short s = 32767; s++;                  /* -32768 */
  signed char sc = 127; sc += 1;         /* -128 */
  short t = -32768; t--;                 /* 32767 */
  unsigned short us = 65535; us *= 2;    /* 65534 */
  signed char m = -128; m = -m;          /* -128 (128 wraps) */
  unsigned char e = 200; e *= 2;         /* 144 */
  printf("%d %d %d %d %d %d %d %d\n", c, d, s, sc, t, us, m, e);
  return 0;
}
