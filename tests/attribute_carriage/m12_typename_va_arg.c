#include <stdarg.h>
int f(int n, ...) { va_list ap; va_start(ap, n); int r = va_arg(ap, int [[m::mk("s")]]); va_end(ap); return r; } int main(void) { return f(1, 0); }
