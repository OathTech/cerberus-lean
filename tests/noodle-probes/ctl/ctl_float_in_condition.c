/* Corner: a floating value in a controlling expression / logical operator
   compares against 0 (ISO C11 6.8.4.1p2, 6.5.3.3p5, 6.5.13, 6.5.15): 0.5 is
   TRUE. Distinct from the _Bool CONVERSION (tray 15). gcc: 1 0 1 1 1 1 */
#include <stdio.h>
int main(void) {
  double h = 0.5, z = 0.0, nz = -0.0;
  int r1; if (h) r1 = 1; else r1 = 2;
  int r2 = !h;                 /* 0 */
  int r3 = h && 1;             /* 1 */
  int r4 = h ? 1 : 2;          /* 1 */
  int r5 = !z + !nz - 1;       /* 1 */
  int r6 = 0; while (h) { r6 = 1; break; }
  printf("%d %d %d %d %d %d\n", r1, r2, r3, r4, r5, r6);
  return 0;
}
