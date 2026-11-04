#include <stdint.h>
#include <stdio.h>
int main(void) { int64_t a = -1; uint64_t b = 1; intmax_t c = -1; uintmax_t d = 1; long e = -1; unsigned long f = 1;
  printf("%d %d %d %d\n", a < b, c < d, e < f, a < f); return 0; }
