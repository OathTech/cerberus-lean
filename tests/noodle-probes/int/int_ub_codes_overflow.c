/* Corner: UB classification for signed overflow in different operators
   (ISO C11 6.5p5). Exhaustive-mode verdict should be UB036 on both engines;
   this probe fixes WHICH operator is reached first: unary minus on INT_MIN. */
int main(void) {
  int m = -2147483647 - 1;
  int r = -m;
  return r & 1;
}
