/* AUDITOR: libc/printf variant of w1-minus7 — the address pristine b9aeedcb4 hands out and the overlap it creates. */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  uintptr_t a; char *p; char *q; size_t sz;
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  sz = (size_t)(a - 7);
  p = malloc(sz);
  printf("live 1-byte object q at %llu (0x%llx); request %llu bytes -> %s", (unsigned long long)a, (unsigned long long)a, (unsigned long long)sz, p ? "ACTIVE" : "NULL");
  if (p) printf(" at %p = %llu; new object [%llu, %llu) contains q: %d, is 8-aligned: %d",
    (void*)p, (unsigned long long)(uintptr_t)p, (unsigned long long)(uintptr_t)p, (unsigned long long)((uintptr_t)p + sz),
    (uintptr_t)p <= a && a < (uintptr_t)p + sz, ((uintptr_t)p % 8) == 0);
  printf("\n");
  return 0;
}
