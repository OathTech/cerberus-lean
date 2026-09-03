/* Corner: brace elision, designators incl. array-index continuation, mixed
   positional after designator, override of an earlier initializer
   (ISO C11 6.7.9p17-20). */
#include <stdio.h>
struct S { int x; int y[2]; int z; };
int main(void) {
  int a[2][3] = {1, 2, 3, 4};                 /* a[1][0] = 4 */
  struct S s = {1, 2, 3, 4};                  /* z = 4 */
  int b[5] = {[3] = 1, 2};                    /* b[4] = 2 */
  int c[3] = {[1] = 5, 6, [0] = 7};           /* 7 5 6 */
  struct S d = {.x = 1, .x = 2};              /* 2 */
  struct S e = {.y = {8, 9}, .x = 3};
  printf("%d %d %d %d %d %d %d %d %d %d\n", a[1][0], a[1][2], s.z, s.y[1], b[4], c[0], c[1], c[2], d.x, e.y[1] + e.x);   /* 4 0 4 3 2 7 5 6 2 12 */
  return 0;
}
