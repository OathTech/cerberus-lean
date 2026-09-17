/* AUDITOR reproducer, libc/printf variant of oneshot.c: the cursor, the request and pristine's address. */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  char *q = malloc(1);
  if (q == NULL) return 3;
  uintptr_t a = (uintptr_t)q;
  size_t sz = (size_t)(a + 1);
  char *p = malloc(sz);
  printf("cursor=%llu (0x%llx) request=%llu -> %s", (unsigned long long)a, (unsigned long long)a, (unsigned long long)sz, p ? "ACTIVE" : "NULL");
  if (p) printf(" at %p: new object [%llu, %llu) overlaps the live 1-byte object at %llu: %d", (void*)p, (unsigned long long)(uintptr_t)p, (unsigned long long)((uintptr_t)p + sz), (unsigned long long)a, (uintptr_t)p <= a && a < (uintptr_t)p + sz);
  printf("\n");
  return 0;
}
