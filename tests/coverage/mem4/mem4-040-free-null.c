// mem4-040: free(NULL) is a no-op, repeatedly; free of a realloc(NULL,..) block.
#include <stdlib.h>
int main(void) {
  free(NULL); free((void *)0); free(NULL);
  char *p = realloc(NULL, 1);
  if (!p) return 255;
  *p = 9;
  int r = *p;
  free(p);
  return r;
}
