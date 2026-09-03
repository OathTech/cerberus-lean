/* Corner: conversion to _Bool from integers whose low byte/word is zero,
   from pointers, and _Bool increment/decrement (ISO C11 6.3.1.2p1:
   any nonzero scalar -> 1). Excludes the float->_Bool case (tray 15). */
#include <stdio.h>
int main(void) {
  int x = 5; int *p = &x; int *q = 0;
  _Bool b1 = 256;                 /* 1 */
  _Bool b2 = 65536;               /* 1 */
  _Bool b3 = 0x100000000LL;       /* 1 */
  _Bool b4 = p;                   /* 1 */
  _Bool b5 = q;                   /* 0 */
  _Bool b6 = 1; b6++;             /* 1 */
  _Bool b7 = 0; b7--;             /* 1 */
  _Bool b8 = 1; b8 += 1;          /* 1 */
  _Bool b9 = (unsigned char)256;  /* 0 */
  _Bool b10 = -1;                 /* 1 */
  printf("%d%d%d%d%d%d%d%d%d%d\n", b1,b2,b3,b4,b5,b6,b7,b8,b9,b10);
  return 0;
}
