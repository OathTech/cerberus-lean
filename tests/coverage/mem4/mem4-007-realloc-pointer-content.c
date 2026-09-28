// mem4-007: realloc of an array of POINTERS: the copied pointers keep their
// provenance and can be dereferenced from the new block.
#include <stdlib.h>
int g1 = 11, g2 = 22;
int main(void) {
  int **v = malloc(2 * sizeof(int *));
  if (!v) return 255;
  int local = 33;
  v[0] = &g1; v[1] = &local;
  int **w = realloc(v, 3 * sizeof(int *));
  if (!w) return 254;
  w[2] = &g2;
  *w[1] += 1;
  int r = *w[0] + *w[1] + *w[2];
  free(w);
  return r + local;
}
