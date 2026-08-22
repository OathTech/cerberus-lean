// G2 control: a fully in-bounds initialised memcpy should MATCH both
// sides (proves the checked path, once installed, keeps good cases green).
#include <string.h>
int main(void) {
  int src[4] = {1,2,3,4};
  int dst[4];
  memcpy(dst, src, sizeof(src));
  return dst[3];
}
