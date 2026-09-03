/* Corner: recursion 500 deep with a 16-int local array per frame, frames
   written and read after return (stack discipline). Within the fuel budget. */
#include <stdio.h>
int rec(int d) {
  int buf[16];
  for (int i = 0; i < 16; i++) buf[i] = d + i;
  if (d == 0) return buf[15];
  int r = rec(d - 1);
  return r + buf[0];            /* sum of d over 0..500 + 15 */
}
int main(void) { printf("%d\n", rec(500)); return 0; }   /* 125250 + 15 = 125265 */
