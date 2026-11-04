#include <stddef.h>
#include <stdio.h>
int main(void) { size_t one = 1; int s = 40; unsigned long long r1 = one << s; unsigned long long r2 = one << 40;
  int i = 1; unsigned long long r3 = (size_t)i << 40; printf("%llu %llu %llu\n", r1, r2, r3); return 0; }
