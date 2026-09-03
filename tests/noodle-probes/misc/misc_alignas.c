/* Corner: _Alignas on an automatic array and on a struct member; observed
   only as alignment residues and sizeof/_Alignof (ISO C11 6.7.5). */
#include <stdio.h>
#include <stdint.h>
struct A { char c; _Alignas(16) char d; };
int main(void) {
  _Alignas(64) char buf[3];
  printf("%d %d %d %d %d\n", (int)((uintptr_t)buf % 64), (int)_Alignof(struct A), (int)sizeof(struct A), (int)sizeof buf, (int)((uintptr_t)&((struct A){0}).d % 16));   /* 0 16 32 3 0 */
  return 0;
}
