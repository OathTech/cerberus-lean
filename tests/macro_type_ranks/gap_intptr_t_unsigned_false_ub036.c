#include <stdint.h>
#include <stdio.h>
int main(void) { intptr_t a = 5; unsigned long b = 18446744073709551610UL;
  printf("%llu\n", (unsigned long long)(a + b)); return 0; }
