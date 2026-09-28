// fmt-042: %u/%x/%o of values from negative ints converted to unsigned, with
// precision padding on large values.
#include <stdio.h>
int main(void) {
  unsigned a = (unsigned)-1, b = (unsigned)-256;
  return printf("[%u|%x|%o|%.12u|%.10x|%X]\n", a, b, a, 7u, a, b);
}
