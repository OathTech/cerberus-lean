#include <stdint.h>
#include <stdio.h>
int main(void) { intptr_t n = 5000000000; int i = 1; char c = 1; short s = 1; unsigned u = 1;
  printf("%lld %lld %lld %lld %lld %lld %lld %d %d\n", (long long)(n + i), (long long)(i + n), (long long)(n - i), (long long)(n * 2), (long long)(n / 2), (long long)(u + n), (long long)(c + n), n == 705032704, (s + n) > 4000000000); return 0; }
