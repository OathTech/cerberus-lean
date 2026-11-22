#include <limits.h>
int main(void) {
  int r = 0;
#if CHAR_MAX > 127
  r += 1;
#endif
#if CHAR_MIN < 0
  r += 2;
#endif
#if '\377' < 0
  r += 4;
#endif
  if (CHAR_MAX > 127) r += 8;
  if (CHAR_MIN < 0) r += 16;
  if ('\377' < 0) r += 32;
  return r;
}
