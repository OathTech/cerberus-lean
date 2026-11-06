/* vprintf, defined in the shipped library since this slice (7.21.6.10): vfprintf(stdout, fmt, ap). gcc: "bc1\n". */
#include <stdio.h>
#include <stdarg.h>
int logv(const char *fmt, ...) { va_list ap; va_start(ap, fmt); int r = vprintf(fmt, ap); va_end(ap); return r; }
int main(void) { fputs("b", stdout); logv("c%d\n", 1); return 0; }
