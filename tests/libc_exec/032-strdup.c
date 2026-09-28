// 032: strdup returns an independent heap copy (malloc inside libc).
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(void) {
  const char *s = "copy";
  char *d = strdup(s);
  if (!d) return 255;
  d[0] = 'C';
  int r = printf("%s %s %d\n", s, d, d != s);
  free(d);
  return r;
}
