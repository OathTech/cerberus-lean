/* Corner: a typedef name redeclared as a variable in an inner scope; struct
   tag redefined in an inner scope; incomplete-then-complete struct
   (ISO C11 6.2.1, 6.7.2.3). */
#include <stdio.h>
typedef int T;
struct S; struct S *gp;
struct S { int v; };
int main(void) {
  T a = 4;
  { int T = 9; a += T; }
  struct S s = {7}; gp = &s;
  { struct S { char c[3]; } inner = {{'a','b'}}; a += (int)sizeof inner; }
  printf("%d %d %d\n", a, gp->v, (int)sizeof(struct S));   /* 16 7 4 */
  return 0;
}
