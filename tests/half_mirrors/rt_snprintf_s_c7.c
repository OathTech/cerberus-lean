/* tray 11 through %s: the stored string's byte 0xC7 = 199 ("\199" on pristine: not an octal constant, rc 125).
   gcc 13: Specified(199). Fixed in the fork 2026-11-07. */
#include <stdio.h>
int main(void) {
  char buf[8];
  snprintf(buf, 8, "%s", "\xc7");
  return (unsigned char)buf[0];
}
