// 025: sprintf (libc C -> vsnprintf builtin) into a buffer; return value and
// the stored text, including width/precision/flags.
#include <stdio.h>
int main(void) {
  char buf[64];
  int n = sprintf(buf, "%-4d|%05.1f|%x|%s|%c", 7, 2.25, 0xbeefu, "ok", 'z');
  return printf("%d:%s\n", n, buf);
}
