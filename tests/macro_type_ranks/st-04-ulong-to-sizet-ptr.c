#include <stddef.h>
int main(void){ unsigned long x = 7; size_t *p = &x; return (int)*p; }
