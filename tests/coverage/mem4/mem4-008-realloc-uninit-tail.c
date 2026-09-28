// mem4-008: the grown tail of a realloc'd block is uninitialised: reading it
// gives an unspecified value (returned as such).
#include <stdlib.h>
int main(void) {
  int *p = malloc(sizeof(int));
  if (!p) return 255;
  *p = 1;
  int *q = realloc(p, 2 * sizeof(int));
  if (!q) return 254;
  return q[1];
}
