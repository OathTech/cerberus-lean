#include <stddef.h>
#include <stdio.h>
int main(void){ ptrdiff_t d = -1; unsigned long u = 1;
  printf("%d %d %llu\n", d < u, u > d, (unsigned long long)(d + u)); return 0; }
