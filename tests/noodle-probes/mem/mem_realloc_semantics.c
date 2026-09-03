/* Corner: realloc(NULL,n) == malloc(n); realloc growth preserves the old
   contents; realloc shrink preserves the prefix (ISO C11 7.22.3.5). */
#include <stdlib.h>
#include <stdio.h>
int main(void) {
  int *p = realloc(0, 2 * sizeof(int));
  p[0] = 11; p[1] = 22;
  p = realloc(p, 6 * sizeof(int));
  p[5] = 66;
  int s1 = p[0] + p[1] + p[5];
  p = realloc(p, 1 * sizeof(int));
  int s2 = p[0];
  free(p);
  printf("%d %d\n", s1, s2);   /* 99 11 */
  return 0;
}
