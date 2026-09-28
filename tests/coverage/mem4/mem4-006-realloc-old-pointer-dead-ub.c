// mem4-006: reading through the OLD pointer after a successful realloc: the
// old allocation is dead (use after free).
#include <stdlib.h>
int main(void) {
  int *p = malloc(2 * sizeof(int));
  if (!p) return 255;
  p[0] = 7;
  int *q = realloc(p, 64 * sizeof(int));
  if (!q) return 254;
  return p[0];
}
