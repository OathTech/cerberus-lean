// mem4-001: realloc grow: every old element (not just the first) survives, the
// new tail is writable, and the result exposes all of them.
#include <stdlib.h>
int main(void) {
  unsigned char *p = malloc(5);
  if (!p) return 255;
  for (int i = 0; i < 5; i++) p[i] = (unsigned char)(0x81 + 17 * i);
  unsigned char *q = realloc(p, 300);
  if (!q) return 254;
  for (int i = 5; i < 300; i++) q[i] = (unsigned char)i;
  unsigned s = 0;
  for (int i = 0; i < 300; i++) s = s * 31u + q[i];
  free(q);
  return (int)(s % 251u);
}
