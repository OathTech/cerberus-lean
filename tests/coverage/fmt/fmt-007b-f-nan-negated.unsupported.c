// fmt-007b: the negated NaN of fmt-007 (the model negates as 0 - x, so the
// sign is whatever that subtraction yields on both engines).
#include <stdio.h>
int main(void) {
  double inf = 1e309;
  double n = -(inf - inf);
  return printf("[%f]\n", n);
}
