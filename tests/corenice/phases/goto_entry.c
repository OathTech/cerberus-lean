#include <stdio.h>

int main(void) {
  int i = 0;
  goto inside;
  while ((printf("T%d", i), i < 2)) {
    printf("B%d", ++i);
inside:
    printf("L%d", i);
  }
  return i != 2;
}
