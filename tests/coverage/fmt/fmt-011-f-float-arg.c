// fmt-011: float arguments are promoted to double: %f shows the exact
// float value (0.1f is not 0.1), FLT_MAX and 2^24 + 1 rounding.
#include <stdio.h>
int main(void) {
  float a = 0.1f, b = 16777217.0f, c = 3.4028234663852886e38f, d = -1.5f;
  return printf("[%.10f|%f|%f|%.1f]\n", a, b, c, d);
}
