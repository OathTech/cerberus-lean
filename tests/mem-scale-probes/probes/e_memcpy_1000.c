#include <string.h>
char a[1000], b[1000];
int main(void) {
  memset(a, 7, 1000);
  memcpy(b, a, 1000);
  return b[1000 - 1];
}
