int main(void) {
  int x = 1;
  int s = 32;
  return x << s;  /* UB: shift >= width */
}
