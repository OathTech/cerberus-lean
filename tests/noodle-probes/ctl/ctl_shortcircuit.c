/* Corner: && and || are sequence points; the right operand is evaluated
   only when needed; result type is int 0/1 (ISO C11 6.5.13, 6.5.14). */
#include <stdio.h>
int calls = 0;
int t(int v) { calls++; return v; }
int main(void) {
  int a = 0, b = 5, x = 0;
  int r1 = a && b++;            /* 0, b stays 5 */
  int r2 = 0 || (x = 7);        /* 1, x = 7 */
  int r3 = t(1) && t(0) && t(1);/* 0, calls = 2 */
  int r4 = t(0) || t(0) || t(3);/* 1, calls = 5 */
  int r5 = (2 && 3) + (0 || 9); /* 2 */
  printf("%d %d %d %d %d %d %d %d\n", r1, b, r2, x, r3, r4, calls, r5);
  return 0;
}
