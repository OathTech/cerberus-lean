/* Corner: rand() after srand(1) is deterministic per implementation
   (ISO C11 7.22.2); gcc/glibc values differ by design — oracle vs Lean
   agreement is the target. */
#include <stdlib.h>
#include <stdio.h>
int main(void) {
  srand(1);
  int a = rand() % 1000, b = rand() % 1000, c = rand() % 1000;
  srand(1);
  int a2 = rand() % 1000;
  printf("%d %d %d %d\n", a, b, c, a == a2);
  return 0;
}
