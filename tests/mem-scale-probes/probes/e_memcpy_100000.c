#include <string.h>
char a[100000], b[100000];
int main(void) {
  memset(a, 7, 100000);
  memcpy(b, a, 100000);
  return b[100000 - 1];
}
