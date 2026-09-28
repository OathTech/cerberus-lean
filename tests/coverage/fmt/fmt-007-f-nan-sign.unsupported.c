// fmt-007: NaN under %f. inf - inf is an IEEE invalid operation producing a
// NaN; its printed text depends on its sign bit (the oracle prints "-nan").
// Lean cannot read a NaN's sign (Float.toBits canonicalizes NaNs), so printing
// a NaN with %f is REFUSED (2026-09-28); this row pins the refusal.
#include <stdio.h>
int main(void) {
  double inf = 1e309;
  double n = inf - inf;
  return printf("[%f|%.2f|%5f]\n", n, n, n);
}
