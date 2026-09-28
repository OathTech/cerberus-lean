// fmt-026: %s with width, '-', precision (truncation), precision 0, and the
// empty string.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%s|%.3s|%5s|%-5s|%.0s]\n", "hello", "hello", "hi", "hi", "gone");
  r += printf("[%10.3s|%-10.3s|%.10s|%s|%3s|%-3s]\n", "abcdef", "abcdef", "abc", "", "", "");
  return r;
}
