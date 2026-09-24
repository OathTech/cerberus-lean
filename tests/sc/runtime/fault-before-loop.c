/* The independent division fault must be reported without reaching the loop.
   The operational prefix also contains the two unordered non-atomic stores. */
int main(void) {
  int x = 0;
  {-{ { x = 1; } ||| { x = 2; } }-};
  int zero = 0;
  x = 1 / zero;
  while (1) {}
  return x;
}
