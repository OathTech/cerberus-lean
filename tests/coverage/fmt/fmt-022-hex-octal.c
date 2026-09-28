// fmt-022: %x %X %o with the '#' alternative form (no prefix for zero),
// zero padding, left justification and precision.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%x|%X|%#x|%#X|%#o|%o|%u]\n", 255u, 255u, 255u, 255u, 8u, 8u, 4294967295u);
  r += printf("[%x|%#x|%#X|%#o|%08x|%-8x|%.4x]\n", 0u, 0u, 0xabcu, 0u, 0xabcu, 0xabcu, 0xabcu);
  r += printf("[%#08x|%#.3o|%#5o|%.0x|%.0o|%#.0o]\n", 0x1fu, 8u, 8u, 0u, 0u, 0u);
  r += printf("[%x|%X|%o]\n", 0xdeadbeefu, 0xcafebabeu, 037777777777u);
  return r;
}
