#include <stdlib.h>
int main(void) {
  int *p = malloc(sizeof(int));
  if (!p) return 99;
  *p = 5;
  free(p);
  return *p;  /* UB: use after free */
}
