#include <stdio.h>

int main(void) {
  int zero = 0;
  do {
    printf("B");
  } while (1 / zero);
  return 0;
}
