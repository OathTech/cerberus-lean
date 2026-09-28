// 013: strcpy/strncpy/strcat/strncat (libc C, string.c): strncpy pads with
// NULs up to n and does NOT terminate when the source is too long; strncat
// always terminates.
#include <stdio.h>
#include <string.h>
int main(void) {
  char a[16], b[8], c[16];
  strcpy(a, "abc");
  memset(b, 'Z', sizeof b);
  strncpy(b, "xy", 6);          /* x y \0 \0 \0 \0 Z Z */
  strcat(a, "def");
  strncat(a, "ghijkl", 3);
  strncpy(c, "0123456789", 4);  /* no terminator in c[0..3] */
  c[4] = 0;
  int pad = 0;
  for (int i = 0; i < 8; i++) pad = pad * 3 + (b[i] == 0 ? 1 : (b[i] == 'Z' ? 2 : 0));
  return printf("%s|%s|%s|%d|%d\n", a, b, c, pad, (int)strlen(a));
}
