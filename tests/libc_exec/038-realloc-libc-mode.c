// 038: realloc in libc mode (0 libc-mode rows before this slice): grow and
// shrink with content checks.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(void) {
  char *p = malloc(4);
  if (!p) return 255;
  memcpy(p, "abc", 4);
  p = realloc(p, 64);
  if (!p) return 254;
  strcat(p, "defghij");
  p = realloc(p, 6);
  if (!p) return 253;
  p[5] = 0;
  int r = printf("%s\n", p);
  free(p);
  return r;
}
