int main(void) {
  int n = 0;
start:
  n++;
  if (n < 3) goto start;
  /* The first entry into start falls through its Esave, without a jump. */
  return n == 3 ? 0 : 1;
}
