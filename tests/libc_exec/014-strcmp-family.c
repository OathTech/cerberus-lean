// 014: strcmp/strncmp compare as unsigned char (0x80 > 'a'); prefix and
// length-limited cases. Signs only.
#include <stdio.h>
#include <string.h>
static int sg(int v) { return v > 0 ? 1 : (v < 0 ? -1 : 0); }
int main(void) {
  char hi[2] = {(char)0x80, 0};
  return printf("%d %d %d %d %d %d %d\n",
    sg(strcmp("abc", "abc")), sg(strcmp("abc", "abd")), sg(strcmp("abcd", "abc")),
    sg(strcmp(hi, "a")), sg(strncmp("abcX", "abcY", 3)), sg(strncmp("ab", "abc", 5)),
    sg(strncmp("zzz", "aaa", 0)));
}
