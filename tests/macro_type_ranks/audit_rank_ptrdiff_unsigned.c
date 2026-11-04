#include <stddef.h>
#include <stdio.h>
int main(void) { ptrdiff_t d = -5; unsigned u = 1; unsigned long ul = 1;
  printf("%lld %d %d %d\n", (long long)(d + u), (d + u) < 0, d < u, d < ul); return 0; }
