#include <stdio.h>
#include <stdarg.h>
static void v(const char *f, ...) { va_list ap; va_start(ap, f); vprintf(f, ap); va_end(ap); }
int main(void) { v("[%*d]\n", 4, 9); return 0; }
