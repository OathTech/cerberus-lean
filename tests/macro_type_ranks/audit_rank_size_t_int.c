#include <stddef.h>
#include <stdio.h>
int main(void) { size_t n = 5000000000; int i = 1; char c = 1; short s = 1; unsigned u = 1;
  printf("%llu %llu %llu %llu %llu %llu %llu %d %d\n", (unsigned long long)(n + i), (unsigned long long)(i + n), (unsigned long long)(n - i), (unsigned long long)(n * 2), (unsigned long long)(n / 2), (unsigned long long)(u + n), (unsigned long long)(c + n), n == 705032704, (s + n) > 4000000000); return 0; }
