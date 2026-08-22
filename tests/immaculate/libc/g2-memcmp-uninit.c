// G2: memcmp reading an uninitialised (unspecified) byte. Upstream's
// per-byte checked load kills / asserts on the unspecified byte; Lean
// reads raw bytemap bytes and returns a value silently.
#include <string.h>
int main(void) {
  char a[4];          // uninitialised
  char b[4] = {0,0,0,0};
  return memcmp(a, b, 4);
}
