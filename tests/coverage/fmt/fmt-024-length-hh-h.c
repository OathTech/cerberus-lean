// fmt-024: hh and h length modifiers convert the promoted int argument back to
// (signed/unsigned) char/short before printing: 300 -> 44, 511 -> 255,
// 70000 -> 4464, -1 -> 65535; plus z and t with their own types.
#include <stdio.h>
#include <stddef.h>
int main(void) {
  int r = 0;
  r += printf("[%hhd|%hhd|%hhu|%hhx|%hd|%hu|%hx]\n", 300, -129, 511, 256 + 0xab, 70000, -1, 0x12345);
  r += printf("[%zu|%td|%zx|%zd]\n", (size_t)5, (ptrdiff_t)-6, (size_t)255, (size_t)7);
  return r;
}
