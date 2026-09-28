// 033: rand() after srand(1) and srand(42): the libc's deterministic LCG
// sequence.
#include <stdio.h>
#include <stdlib.h>
int main(void) {
  srand(1);
  int a = rand(), b = rand();
  srand(42);
  int c = rand();
  srand(1);
  int d = rand();
  return printf("%d %d %d %d\n", a, b, c, a == d);
}
