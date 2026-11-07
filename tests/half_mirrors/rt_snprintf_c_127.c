/* tray 11's reproducer: the %c store of 127 read back (C17 7.21.6.1#8: the int argument converted to unsigned
   char is written). gcc 13: Specified(127). Pristine c3ff8c53f: Specified(87) (Char.escaped's decimal "\127"
   read back as octal); fixed in the fork 2026-11-07 (decode.ml escaped_char mirrors CerbDecode.escaped_char). */
#include <stdio.h>
int main(void) {
  char buf[8];
  snprintf(buf, 8, "%c", 127);
  return buf[0];
}
