#include <stdio.h>

int main(void) {
  while ((printf("W"), 1)) {
    printf("A");
    break;
  }
  do {
    printf("B");
    break;
  } while ((printf("D"), 1));
  for (; (printf("F"), 1); printf("I")) {
    printf("C");
    break;
  }
  return 0;
}
