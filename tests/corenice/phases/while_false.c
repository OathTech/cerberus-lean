#include <stdio.h>

int main(void) {
  int bodies = 0;
  while ((printf("F"), 0)) {
    printf("B%d", ++bodies);
  }
  return bodies;
}
