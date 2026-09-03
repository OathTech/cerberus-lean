/* Corner: function pointer equality, & and * on function designators,
   casts between function pointer types and back (ISO C11 6.5.3.2p4,
   6.3.2.3p8, 6.5.9p6). Sequenced statements (no unsequenced calls). */
#include <stdio.h>
int f(int x) { return x + 1; }
int g(int x) { return x + 2; }
int main(void) {
  int (*pf)(int) = f;
  void (*pv)(void) = (void(*)(void))g;
  int (*pg)(int) = (int(*)(int))pv;
  int e1 = pf == f, e2 = pf == &f, e3 = pf != g;
  int v1 = (*pf)(1); int v2 = (**pf)(1); int v3 = pg(1);
  printf("%d %d %d %d %d %d\n", e1, e2, e3, v1, v2, v3);   /* 1 1 1 2 2 3 */
  return 0;
}
