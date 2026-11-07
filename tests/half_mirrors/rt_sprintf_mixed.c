/* tray 11 through sprintf with mixed conversions: %c of 127, 200 and 19, then a %s carrying a UTF-8 lead byte,
   a tab and a newline; the sum of the stored bytes. gcc 13: (127 + 200 + 19 + 195 + 169 + 9 + 10) & 0xff = 217,
   Specified(217). Pristine c3ff8c53f: rc 125 (19 -> "\019"). Fixed in the fork 2026-11-07. */
#include <stdio.h>
int main(void) {
  char buf[16];
  int n = sprintf(buf, "%c%c%c%s", 127, 200, 19, "\xc3\xa9\t\n");
  int s = 0;
  for (int i = 0; i < n; i++) s += (unsigned char)buf[i];
  return s & 0xff;
}
