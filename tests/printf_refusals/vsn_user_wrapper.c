#include <stdio.h>
#include <stdarg.h>
static int w(char *s, size_t n, const char *f, ...) { va_list ap; va_start(ap, f); int r = vsnprintf(s, n, f, ap); va_end(ap); return r; }
int main(void) { char b[4]; int n = w(b, sizeof b, "%d", 123456); printf("%d:%s\n", n, b); return 0; }
