#include <stdlib.h>
int main(void) {
  char *end;
  long a = strtol("  -42xyz", &end, 10);
  long b = strtol("0x1f", (char**)0, 16);
  long c = strtol("101", (char**)0, 2);
  return (a == -42) + (*end == 'x') + (b == 31) + (c == 5);  /* 4 */
}
