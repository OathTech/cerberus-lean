#include <stdio.h>

int main(void) {
  int zero = 0;
  printf("before UB\n");
  return 1 / zero;
}
