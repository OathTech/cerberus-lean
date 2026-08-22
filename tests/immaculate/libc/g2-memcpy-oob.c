// G2: memcpy writing past the end of the destination allocation. Upstream
// routes memcpy through per-byte checked store -> OOB store kills; Lean
// copies raw bytemap bytes -> silently succeeds. S1 (checked per-byte).
#include <string.h>
int main(void) {
  char dst[4];
  char src[8] = {1,2,3,4,5,6,7,8};
  memcpy(dst, src, 8);   // writes 8 into a 4-byte object: OOB store
  return dst[0];
}
