#include <limits.h>
int main(void) {
  int r = 0;
  if (CHAR_MIN == 0) r += 1;
  if (CHAR_MAX == 255) r += 2;
  if (CHAR_MIN == SCHAR_MIN) r += 4;
  if (CHAR_MAX == SCHAR_MAX) r += 8;
  if (CHAR_MAX == UCHAR_MAX) r += 16;
  if (CHAR_MAX - CHAR_MIN == 255) r += 32;
  if (CHAR_BIT == 8) r += 64;
  return r;
}
