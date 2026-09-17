/* AUDITOR reproducer, libc/printf variant: show the cursor, the request and the address pristine hands out. */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  uintptr_t a = 0;
  for (unsigned i = 0; i < 65536u; i++) { char *p = malloc(0xFFFFFFF0u); if (!p) return 3; a = (uintptr_t)p; }
  size_t sz = (size_t)(a + 1);
  char *q = malloc(sz);
  printf("cursor=%llu request=%llu -> %s", (unsigned long long)a, (unsigned long long)sz, q ? "ACTIVE" : "NULL");
  if (q) printf(" at %p; new object [%llu, %llu) overlaps the live object at %llu: %d", (void*)q, (unsigned long long)(uintptr_t)q, (unsigned long long)((uintptr_t)q + sz), (unsigned long long)a, (uintptr_t)q <= a && a < (uintptr_t)q + sz);
  printf("\n");
  return 0;
}
