#include <stdlib.h>
#include <string.h>
int main(void) {
  int r = 0;
  char *p = malloc(2);
  if (!p) return 255;
  p[0] = (char)200; p[1] = (char)129;
  p = realloc(p, 8);
  if (!p) return 254;
  if (p[0] > 0) r += 1;
  if (p[0] + p[1] == 329) r += 2;
  if (p[0] + p[1] == -183) r += 4;
  p[7] = (char)255;
  char *q = realloc(p, 16);
  if (!q) return 253;
  if (q[7] == 255) r += 8;
  if (q[7] == -1) r += 16;
  if (q[1] > 127) r += 32;
  free(q);
  return r;
}
