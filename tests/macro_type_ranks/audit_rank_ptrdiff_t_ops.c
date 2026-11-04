#include <stddef.h>
#include <stdio.h>
int main(void) { ptrdiff_t n = 5000000000; int i = 3;
  printf("%lld %lld %lld %lld %lld %lld %d %d %d\n", (long long)(n & i), (long long)(n | i), (long long)(n ^ i), (long long)(n % i), (long long)(i ? n : i), (long long)(n >> i), n > i, i < n, n != i); return 0; }
