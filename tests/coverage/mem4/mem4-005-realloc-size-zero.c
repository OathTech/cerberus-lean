// mem4-005: realloc(p, 0): implementation-defined result; the observable is
// whether the result is null and whether writing to the old block is still
// possible is NOT tested (the old block is freed).
#include <stdlib.h>
int main(void) {
  char *p = malloc(4);
  if (!p) return 255;
  p[0] = 'x';
  char *q = realloc(p, 0);
  return q == NULL ? 1 : 2;
}
