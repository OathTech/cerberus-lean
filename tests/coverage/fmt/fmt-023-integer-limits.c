// fmt-023: integer extremes through %d %i %u and the l / ll length modifiers.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%i|%d|%d|%u]\n", -0, -2147483647 - 1, 2147483647, 0u);
  r += printf("[%lu|%lx|%llx|%ld|%lld]\n", 18446744073709551615ul, 0xdeadbeefcafebabeul, 0x123456789abcdef0ull, -3L, -4LL);
  r += printf("[%ld|%lld|%llu|%lo]\n", -9223372036854775807L - 1, 9223372036854775807LL, 18446744073709551615ull, 01777777777777777777777ul);
  return r;
}
