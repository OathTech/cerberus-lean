// fmt-025: %% and %c: printable, width/justified, and edge char values: 127,
// 200, -1 (0xff), 321 (converted to unsigned char = 'A'), 0 (a NUL byte in
// stdout). Hand-written escaping (CerbEscape / encode_character_constant).
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%%|%c|%c|%5c|%-5c|%%%%]\n", 'a', 65, 'q', 'q');
  r += printf("[%c|%c|%c|%c|%c]\n", 127, 200, -1, 321, 0);
  r += printf("[%c%c%c]\n", '\t', '\n', '\\');
  return r;
}
