#include <stdint.h>
#include <stdio.h>
int main(void) { uintptr_t n = 5000000000; int i = 3;
  printf("%llu %llu %llu %llu %llu %llu %d %d %d\n", (unsigned long long)(n & i), (unsigned long long)(n | i), (unsigned long long)(n ^ i), (unsigned long long)(n % i), (unsigned long long)(i ? n : i), (unsigned long long)(n >> i), n > i, i < n, n != i); return 0; }
