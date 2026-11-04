#include <stdint.h>
#include <stdio.h>
int main(void) { uint32_t u = 4000000000u; int i = -1; long l = -1;
  printf("%d %d %llu %llu %d\n", u > i, u > l, (unsigned long long)(u + i), (unsigned long long)(u + l), (i + u) > 0); return 0; }
