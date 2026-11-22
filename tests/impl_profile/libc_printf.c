#include <stdio.h>
#include <limits.h>
int main(void) {
  char c = '\377';
  char s[] = "\200x";
  printf("%d %d %d %d\n", c, s[0], CHAR_MIN, CHAR_MAX);
  printf("%u %x\n", (unsigned)c, (unsigned)(c & 0xff));
  printf("%c%c\n", 'o', 'k');
  return c > 0;
}
