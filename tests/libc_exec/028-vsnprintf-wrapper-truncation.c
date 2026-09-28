// 028: a user variadic wrapper over vsnprintf with truncation and several
// argument types (va_list passed to the builtin).
#include <stdarg.h>
#include <stdio.h>
static int fmt(char *out, unsigned long n, const char *f, ...) {
  va_list ap;
  va_start(ap, f);
  int r = vsnprintf(out, n, f, ap);
  va_end(ap);
  return r;
}
int main(void) {
  char buf[10];
  int r1 = fmt(buf, sizeof buf, "%s-%d-%u-%c", "abc", -12, 345u, 'q');
  int r2 = fmt(buf + 5, 3, "%x", 0xabcdu);
  return printf("%d %d %s\n", r1, r2, buf);
}
