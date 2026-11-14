#include <stdio.h>

static unsigned left, right;
static unsigned f(void) { printf("F"); left = 1; return 1; }
static unsigned g(void) { printf("G"); right = 1; return 2; }

int main(void) {
  unsigned sum = f() + g();
  printf("\n");
  return (int)(sum + left + right);
}
