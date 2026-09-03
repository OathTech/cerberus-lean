/* Corner: converting NaN (from inf-inf, no division) to int is UB
   (ISO C11 6.3.1.4p1). Both engines should give a UB verdict, not a crash. */
int main(void) {
  double big = 1e308;
  double inf = big * 10;
  double nan = inf - inf;
  int i = (int)nan;
  return i & 1;
}
