#include <string.h>
char a[1000000], b[1000000];
int main(void) {
  memset(a, 7, 1000000);
  memcpy(b, a, 1000000);
  return b[1000000 - 1];
}
