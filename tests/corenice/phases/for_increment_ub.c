#include <stdio.h>

int main(void) {
  int zero = 0;
  for (; (printf("T"), 1); (printf("I"), 1 / zero)) {
    printf("B");
  }
  return 0;
}
