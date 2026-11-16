#include <stdio.h>

int main(void) {
  int bodies = 0, guards = 0;
  do {
    printf("B%d", ++bodies);
  } while ((printf("T%d", ++guards), guards < 2));
  return bodies != 2 || guards != 2;
}
