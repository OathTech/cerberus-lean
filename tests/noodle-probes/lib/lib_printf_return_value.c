/* Corner: printf/putchar return values (ISO C11 7.21.6.3p3, 7.21.7.8):
   count of bytes written. (puts kept out: see lib_stdio_puts_after_putchar.c.) */
#include <stdio.h>
int main(void) {
  int a = printf("abc\n");            /* 4 */
  int b = printf("%d|%5d", 12345, 7); /* 11 */
  int c = putchar('\n');              /* 10 */
  int e = printf("");                 /* 0 */
  printf("%d %d %d %d\n", a, b, c, e);
  return 0;
}
