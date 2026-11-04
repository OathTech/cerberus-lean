#include <stddef.h>
#include <stdio.h>
int main(void) { size_t n = 5000000000; int i = 1; n += i; size_t m = 5000000000; m -= i; size_t k = 5000000000; k *= 2;
  printf("%llu %llu %llu\n", (unsigned long long)n, (unsigned long long)m, (unsigned long long)k); return 0; }
