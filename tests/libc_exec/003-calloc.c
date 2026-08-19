#include <stdlib.h>
int main(void) {
  int *p = calloc(4, sizeof(int));
  int s = p[0] + p[3];
  p[2] = 5;
  s += p[2];
  free(p);
  return s;
}
