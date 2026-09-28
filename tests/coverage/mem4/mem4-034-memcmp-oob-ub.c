// mem4-034: memcmp reading one byte past the end of an object.
#include <string.h>
int main(void) {
  char a[2] = {1, 2}, b[4] = {1, 2, 3, 4};
  return memcmp(a, b, 3);
}
