// mem4-009: freeing the old pointer after a successful realloc is a double free.
#include <stdlib.h>
int main(void) {
  char *p = malloc(4);
  if (!p) return 255;
  char *q = realloc(p, 400);
  if (!q) return 254;
  free(p);
  return 0;
}
