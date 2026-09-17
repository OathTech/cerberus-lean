/* AUDITOR side-observation #2: does the 32-bit truncation of `(size_t)a + 1` need pointer provenance? */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  char *q = malloc(1);
  uintptr_t a = (uintptr_t)q;                       /* pointer-derived (provenance) */
  unsigned long b = 281474976705856ULL;             /* plain integer of the same magnitude */
  uintptr_t c = 281474976705856ULL;                 /* uintptr_t, not pointer-derived */
  printf("ptr-derived: (size_t)a+1=%llu (unsigned long)a+1=%llu (uintptr_t)a+1=%llu (size_t)a+0=%llu (size_t)a*1=%llu (size_t)a-1=%llu\n",
    (unsigned long long)((size_t)a + 1), (unsigned long long)((unsigned long)a + 1), (unsigned long long)((uintptr_t)a + 1),
    (unsigned long long)((size_t)a + 0), (unsigned long long)((size_t)a * 1), (unsigned long long)((size_t)a - 1));
  printf("plain ulong: (size_t)b+1=%llu; plain uintptr_t: (size_t)c+1=%llu (uintptr_t)c+1=%llu\n",
    (unsigned long long)((size_t)b + 1), (unsigned long long)((size_t)c + 1), (unsigned long long)((uintptr_t)c + 1));
  return 0;
}
