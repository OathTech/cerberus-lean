#include <stddef.h>
static int f(unsigned long *p){ return (int)*p; }
int main(void){ size_t n = 4; return f(&n); }
