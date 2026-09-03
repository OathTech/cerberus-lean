/* Corner: snprintf with enough room: content, NUL, return value (ISO C11
   7.21.6.5). The truncation return-value case is tray 16 (excluded). */
#include <stdio.h>
int main(void) {
  char b[16];
  int n = snprintf(b, sizeof b, "%d-%s", 42, "x");   /* "42-x", 4 */
  printf("%s %d %d\n", b, n, b[4] == 0);
  return 0;
}
