/* AUDITOR reproducer, libc variant: prints the address the pristine oracle hands out in the exhausted regime. */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  char *q = malloc(1);
  if (q == NULL) return 3;
  size_t sz = (size_t)(uintptr_t)q + 1;
  char *p = malloc(sz);
  if (p == NULL) return 4;
  printf("q=%p p=%p overlap=%d\n", (void*)q, (void*)p, (uintptr_t)p <= (uintptr_t)q && (uintptr_t)q < (uintptr_t)p + sz);
  return 0;
}
