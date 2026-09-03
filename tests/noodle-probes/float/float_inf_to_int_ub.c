/* Corner: converting an out-of-range double (1e300) to int is UB
   (ISO C11 6.3.1.4p1). */
int main(void) {
  double big = 1e300;
  int i = (int)big;
  return i & 1;
}
