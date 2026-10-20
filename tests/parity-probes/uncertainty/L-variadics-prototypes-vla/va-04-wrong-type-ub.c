#include <stdarg.h>
static long first(int n, ...){ va_list ap; va_start(ap, n); long l = va_arg(ap, long); va_end(ap); return l; }
int main(void){ return (int)first(1, 5); }
