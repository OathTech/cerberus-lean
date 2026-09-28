// mem4-032: memcmp with length 0 is 0 even when the bytes differ; a prefix
// compare stops before the differing byte.
#include <string.h>
int main(void) {
  char a[3] = {1, 2, 3}, b[3] = {9, 2, 4};
  int r0 = memcmp(a, b, 0);
  int r1 = memcmp(a + 1, b + 1, 1);
  int r2 = memcmp(a, b, 3);
  return (r0 == 0) * 10 + (r1 == 0) * 5 + (r2 != 0);
}
