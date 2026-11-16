#include <stdio.h>

int main(void) {
  int i = 0;
  do {
    switch (i) {
      case 0:
        i = 1;
        printf("B");
        continue;
      default:
        printf("C");
        break;
    }
    printf("D");
    break;
  } while ((printf("T"), i < 2));
  return i != 1;
}
