// fmt-030: printf's return value counts padding, sign, prefix and '%%'; an
// empty format returns 0.
#include <stdio.h>
int main(void) {
  int a = printf("%10d", 1);
  int b = printf("%-3s|", "abcdef");
  int c = printf("%#x%%", 255u);
  int d = printf("");
  int e = printf("\n");
  return a * 10000 + b * 1000 + c * 10 + d + e * 100;
}
