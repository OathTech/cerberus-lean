/* AUDITOR side-observation: (size_t)a + 1 printed as a 32-bit-truncated value in oom-window-debug.c — isolate. */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  char *q = malloc(1);
  uintptr_t a = (uintptr_t)q;
  size_t s0 = (size_t)a;
  size_t s1 = (size_t)a + 1;
  size_t s2 = (size_t)(a + 1);
  unsigned long s3 = a + 1;
  uintptr_t s4 = a + 1;
  unsigned long long s5 = (unsigned long long)a + 1;
  printf("a=%llu (size_t)a=%llu (size_t)a+1=%llu (size_t)(a+1)=%llu (unsigned long)(a+1)=%llu a+1=%llu (ull)a+1=%llu\n",
    (unsigned long long)a, (unsigned long long)s0, (unsigned long long)s1, (unsigned long long)s2, (unsigned long long)s3, (unsigned long long)s4, s5);
  return 0;
}
