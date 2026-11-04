#include <stddef.h>
#include <stdio.h>
int main(void){ ptrdiff_t d = (ptrdiff_t)1 << 33; int i = 1;
  printf("%lld %lld %d %d\n", (long long)(i + d), (long long)(d + i), i < d, d > i); return 0; }
