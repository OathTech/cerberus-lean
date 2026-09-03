/* Corner: static inline, _Noreturn, restrict-qualified parameters
   (ISO C11 6.7.4, 6.7.3.1). */
#include <stdio.h>
#include <stdlib.h>
static inline int twice(int x) { return 2 * x; }
_Noreturn void die(int code) { printf("bye"); exit(code); }
int add(int *restrict a, const int *restrict b) { *a += *b; return *a; }
int main(void) {
  int x = 1, y = 2;
  int r = twice(add(&x, &y));   /* 6 */
  if (r == 6) die(3);
  return 0;
}
