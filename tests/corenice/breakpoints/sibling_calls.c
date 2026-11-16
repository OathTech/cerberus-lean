#include <stdio.h>

/* Distinct call alternatives update disjoint objects. Their output identifies
   the selected execution order independently of the final arithmetic result. */
static int left(int *value) {
  *value = *value + 1;
  printf("L");
  return *value;
}
static int right(int *value) {
  *value = *value + 2;
  printf("R");
  return *value;
}
int main(void) {
  int a = 0;
  int b = 0;
  int sum = left(&a) + right(&b);
  printf("\n");
  return sum == 3 && a == 1 && b == 2 ? 0 : 1;
}
