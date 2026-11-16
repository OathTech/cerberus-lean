#include <stdio.h>

int main(void) {
  int guards = 0, bodies = 0;
  while ((printf("T%d", ++guards), guards < 3)) {
    printf("B%d", ++bodies);
    continue;
  }
  return guards != 3 || bodies != 2;
}
