// G2: memcpy INTO a read-only (const-qualified / string-literal) object.
// Upstream's checked store kills (MerrWriteOnReadOnly); Lean writes raw.
#include <string.h>
int main(void) {
  const char dst[4] = {0,0,0,0};
  char src[4] = {1,2,3,4};
  memcpy((void*)dst, src, 4);   // write on read-only
  return dst[0];
}
