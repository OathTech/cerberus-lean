#include <stdarg.h>
int f(int n, ...) {
  va_list ap, aq; va_start(ap, n);
  va_copy(aq, ap);
  int a = va_arg(ap, int);
  int b = va_arg(aq, int);  /* same first arg */
  va_end(ap); va_end(aq);
  return a + b;
}
int main(void) { return f(1, 21); }  /* 42 */
