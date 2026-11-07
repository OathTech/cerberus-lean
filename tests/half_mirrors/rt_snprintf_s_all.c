/* tray 11 through %s: every byte 1..255 as a one-character string through snprintf's %s store, read back as
   unsigned char; prints each stored value and the mismatch count. gcc 13: the 255 values in order, bad=0,
   Specified(0). Pristine c3ff8c53f: rc 125 at 19. Fixed in the fork 2026-11-07. */
#include <stdio.h>
int main(void) {
  char src[2] = {0, 0};
  char buf[4];
  int bad = 0;
  for (int i = 1; i < 256; i++) {
    src[0] = (char)i; buf[0] = 1; buf[1] = 1;
    int r = snprintf(buf, 4, "%s", src);
    int v = (unsigned char)buf[0];
    if (v != i || r != 1 || buf[1] != 0) bad++;
    printf("%d%c", v, (i % 32 == 31) ? '\n' : ' ');
  }
  printf("bad=%d\n", bad);
  return bad;
}
