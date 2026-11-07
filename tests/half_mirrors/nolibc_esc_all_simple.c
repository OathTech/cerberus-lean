/* every simple escape sequence of C17 6.4.4.4#1 as a character constant and inside one string literal, printed
   through the std.core printf proxy (--nolibc): gcc 13 prints the same two lines and Specified(0). Pristine
   c3ff8c53f: rc 125 at the \? constant. Fixed in the fork 2026-11-07. */
#include <stdio.h>
int main(void) {
  printf("%d %d %d %d %d %d %d %d %d %d %d\n", '\'', '\"', '\?', '\\', '\a', '\b', '\f', '\n', '\r', '\t', '\v');
  const char *s = "\'\"\?\\\a\b\f\n\r\t\v";
  for (int i = 0; s[i]; i++) printf("%d ", s[i]);
  printf("%d\n", (int)sizeof("\'\"\?\\\a\b\f\n\r\t\v"));
  return 0;
}
