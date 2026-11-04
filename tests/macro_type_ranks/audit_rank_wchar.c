#include <stddef.h>
#include <stdio.h>
int main(void) { wchar_t w = 100000; int i = 1; unsigned u = 1; long l = 5000000000L;
  printf("%ld %ld %d %d %ld\n", (long)(w + i), (long)(w + u), w > -1, (w - 200000) < 0, (long)(w + l)); return 0; }
