/* Corner: UB classification for % by zero (ISO C11 6.5.5p5), unsigned operands. */
int main(void) {
  unsigned a = 7, z = 0;
  unsigned r = a % z;
  return r & 1;
}
