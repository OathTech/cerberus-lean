/* tray 11, the whole byte range: every value 0..255 through the %c store of snprintf and read back as unsigned
   char; prints each stored value (32 per line) and the count of mismatches. gcc 13: the 256 values in order,
   bad=0, Specified(0). Pristine c3ff8c53f: rc 125 at the first value whose decimal escape contains a 9 (19);
   before that it would have stored 18 as 16 silently. Fixed in the fork 2026-11-07. */
#include <stdio.h>
int main(void) {
  char buf[4];
  int bad = 0;
  for (int i = 0; i < 256; i++) {
    buf[0] = 1; buf[1] = 1;
    int r = snprintf(buf, 4, "%c", i);
    int v = (unsigned char)buf[0];
    if (v != i || r != 1 || buf[1] != 0) bad++;
    printf("%d%c", v, (i % 32 == 31) ? '\n' : ' ');
  }
  printf("bad=%d\n", bad);
  return bad;
}
