int main(void) {
  /* These operations exercise parsed implementation/runtime procedures too. */
  int x = -17;
  int q = x / 5;
  int r = x % 5;
  unsigned int bits = 3;
  bits = (bits << 3) | 1;
  return q == -3 && r == -2 && bits == 25 ? 0 : 1;
}
