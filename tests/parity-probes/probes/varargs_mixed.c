#include <stdarg.h>
int f(int n, ...) {
  va_list ap; va_start(ap, n);
  int acc = 0;
  acc += va_arg(ap, int);
  acc += (int)va_arg(ap, double);
  int *p = va_arg(ap, int*);
  acc += *p;
  va_end(ap);
  return acc;
}
int main(void) {
  int x = 7;
  return f(3, 10, 20.5, &x);  /* 10+20+7 = 37 */
}
