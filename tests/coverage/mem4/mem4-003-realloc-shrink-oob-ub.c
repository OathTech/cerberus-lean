// mem4-003: after shrinking, the old tail is out of bounds of the new block.
#include <stdlib.h>
int main(void) {
  int *p = malloc(8 * sizeof(int));
  if (!p) return 255;
  for (int i = 0; i < 8; i++) p[i] = i;
  int *q = realloc(p, 2 * sizeof(int));
  if (!q) return 254;
  return q[5];
}
