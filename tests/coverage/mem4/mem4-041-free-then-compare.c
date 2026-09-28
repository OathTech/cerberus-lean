// mem4-041: after free, the pointer's value is indeterminate; comparing it
// (a read of the dead pointer object value) — observable per engine.
#include <stdlib.h>
int main(void) {
  int *p = malloc(sizeof(int));
  if (!p) return 255;
  int *q = p;
  free(p);
  return q == p;
}
