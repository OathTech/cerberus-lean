#include <stdint.h>
int main(void){ uintptr_t u = 9; unsigned long *p = &u; return (int)*p; }
