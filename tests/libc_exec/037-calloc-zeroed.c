// 037: calloc zero-fills: ints read back 0, a pointer member reads back NULL,
// a struct's padding-free members are all zero.
#include <stdio.h>
#include <stdlib.h>
struct s { long a; int *p; char c[3]; };
int main(void) {
  int *a = calloc(5, sizeof(int));
  int **p = calloc(2, sizeof(int *));
  struct s *t = calloc(1, sizeof(struct s));
  if (!a || !p || !t) return 255;
  int r = printf("%d %d %ld %d %d\n", a[0] + a[4], p[1] == NULL, t->a, t->p == NULL, t->c[2]);
  free(a); free(p); free(t);
  return r;
}
