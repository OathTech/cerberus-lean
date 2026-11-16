#include <stdio.h>

int main(void) {
  int i = 0, guards = 0, bodies = 0, increments = 0;
  for (; (printf("T%d", ++guards), i < 2);
       (++i, printf("I%d", ++increments))) {
    printf("B%d", ++bodies);
    continue;
  }
  return i != 2 || guards != 3 || bodies != 2 || increments != 2;
}
