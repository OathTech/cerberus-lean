// mem4-004: realloc(NULL, n) behaves like malloc(n).
#include <stdlib.h>
int main(void) {
  long *p = realloc(NULL, 4 * sizeof(long));
  if (!p) return 255;
  p[3] = 41;
  p[0] = 1;
  long r = p[0] + p[3];
  free(p);
  return (int)r;
}
