// fmt-010: field width and the '-', '0', '+', ' ' flags on %f, including the
// '0' flag with a negative value (the sign goes before the zeros).
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%12f|%-12f|%012f|%012.3f]\n", 3.25, 3.25, -3.25, -3.25);
  r += printf("[%+012.3f|% 012.3f|%-+12.2f|% .1f|%3.1f]\n", 2.5, 2.5, 2.5, 2.5, 123.25);
  r += printf("[%1f|%0.0f|%-1.0f]\n", 12.5, 12.5, 12.5);
  return r;
}
