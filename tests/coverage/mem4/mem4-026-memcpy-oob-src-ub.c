// mem4-026: memcpy reading past the end of the SOURCE object.
#include <string.h>
int main(void) {
  char src[3] = {1, 2, 3};
  char dst[8];
  memcpy(dst, src, 4);
  return dst[0];
}
