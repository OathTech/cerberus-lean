#include <string.h>
char a[10000], b[10000];
int main(void) {
  memset(a, 7, 10000);
  memcpy(b, a, 10000);
  return b[10000 - 1];
}
