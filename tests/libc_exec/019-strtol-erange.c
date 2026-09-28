// 019: strtol overflow saturates to LONG_MAX / LONG_MIN and sets errno =
// ERANGE; a successful conversion after errno = 0 leaves it 0.
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
int main(void) {
  int e0 = errno;
  long v = strtol("99999999999999999999", 0, 10);
  int e1 = errno;
  errno = 0;
  long w = strtol("-99999999999999999999", 0, 10);
  int e2 = errno;
  errno = 0;
  long x = strtol("42", 0, 10);
  return printf("%d %ld %d %ld %d %ld %d\n", e0, v, e1 == ERANGE, w, e2 == ERANGE, x, errno);
}
