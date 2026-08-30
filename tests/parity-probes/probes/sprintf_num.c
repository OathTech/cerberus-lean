#include <stdio.h>
#include <string.h>
int main(void) {
  char b[32];
  int n = sprintf(b, "%d:%x:%05d", 42, 255, 7);
  return n + (strcmp(b, "42:ff:00007") == 0);  /* 11 + 1 = 12 */
}
