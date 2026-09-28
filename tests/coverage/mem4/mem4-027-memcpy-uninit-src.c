// mem4-027: memcpy of an uninitialised source: the destination becomes
// unspecified too; reading it returns an unspecified value.
#include <string.h>
int main(void) {
  int a, b = 3;
  memcpy(&b, &a, sizeof b);
  return b;
}
