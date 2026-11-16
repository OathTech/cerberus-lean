#include <stdio.h>

int main(void) {
  do {
    printf("R");
    return 0;
  } while ((printf("T"), 1));
}
