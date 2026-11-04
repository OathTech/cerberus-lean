#include <stddef.h>
int main(void) { size_t x = (size_t)1 << 32; return (x > 0) + 2*(x + 0 == x) + 4*(x * 1 == x); }
