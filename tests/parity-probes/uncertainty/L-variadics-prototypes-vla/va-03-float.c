#include <stdarg.h>
static double first(int n, ...){ va_list ap; va_start(ap, n); double d = va_arg(ap, double); va_end(ap); return d; }
int main(void){ float f = 2.5f; return (int)(first(1, f) * 2); }
