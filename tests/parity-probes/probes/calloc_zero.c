#include <stdlib.h>
int main(void) {
  int *p = calloc(5, sizeof(int));
  if (!p) return 99;
  int s = 0;
  for (int i = 0; i < 5; i++) s += p[i];
  free(p);
  return s + 42;  /* 42 */
}
