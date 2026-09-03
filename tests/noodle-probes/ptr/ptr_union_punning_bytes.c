/* Corner: type punning through a union to unsigned char (always allowed)
   and to a same-size unsigned type (ISO C11 6.5.2.3p3 fn 95, 6.2.6.1):
   little-endian byte order, two's complement, IEEE-754 double bits. */
#include <stdio.h>
int main(void) {
  union U1 { int i; unsigned char b[4]; } u1;
  union U2 { double d; unsigned long long u; } u2;
  union U3 { short s; unsigned char b[2]; } u3;
  union U4 { unsigned char b[8]; long long ll; } u4;
  u1.i = 0x01020304;
  u2.d = 1.0;
  u3.s = -2;
  for (int k = 0; k < 8; k++) u4.b[k] = (unsigned char)(k + 1);
  printf("%d %d %d %d ", u1.b[0], u1.b[1], u1.b[2], u1.b[3]);          /* 4 3 2 1 */
  printf("%llu ", u2.u);                                                /* 4607182418800017408 */
  printf("%d %d ", u3.b[0], u3.b[1]);                                   /* 254 255 */
  printf("%lld\n", u4.ll);                                              /* 578437695752307201 */
  return 0;
}
