int main(void) {
  int a = -2147483647 - 1;
  int b = -1;
  return a / b == 0;  /* UB050 expected: signed overflow */
}
