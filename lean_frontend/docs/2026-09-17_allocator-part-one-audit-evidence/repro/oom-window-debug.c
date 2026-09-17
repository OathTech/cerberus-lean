/* AUDITOR: what does the exhausted-regime reproducer actually compute? (libc mode, printf) */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  char *q = malloc(1);
  if (q == NULL) return 3;
  uintptr_t a = (uintptr_t)q;
  size_t sz = (size_t)a + 1;
  printf("q=%p a=%llu sz=%llu\n", (void*)q, (unsigned long long)a, (unsigned long long)sz);
  char *p = malloc(sz);
  if (p == NULL) return 4;
  printf("p=%p overlap=%d\n", (void*)p, (uintptr_t)p <= a && a < (uintptr_t)p + sz);
  return 0;
}
