// 034: puts/putchar/fputs/fputc/fwrite to stdout and fputs to stderr; their
// return values.
#include <stdio.h>
int main(void) {
  int a = puts("p");
  int b = putchar('c');
  int c = fputs("f", stdout);
  int d = fputc('\n', stdout);
  size_t e = fwrite("wx\n", 1, 3, stdout);
  int f = fputs("err\n", stderr);
  return printf("%d %d %d %d %d %d\n", a >= 0, b, c >= 0, d, (int)e, f >= 0);
}
