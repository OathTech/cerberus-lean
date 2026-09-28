// mem4-002: realloc shrink keeps the prefix; the shrunk block is the new
// allocation's full extent (index 2 in bounds, results summed).
#include <stdlib.h>
int main(void) {
  int *p = malloc(8 * sizeof(int));
  if (!p) return 255;
  for (int i = 0; i < 8; i++) p[i] = 100 + i;
  int *q = realloc(p, 3 * sizeof(int));
  if (!q) return 254;
  int r = q[0] + q[1] * 2 + q[2] * 3;
  free(q);
  return r - 600;
}
