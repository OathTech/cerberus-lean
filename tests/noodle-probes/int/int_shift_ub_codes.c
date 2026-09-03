/* Corner: UB classification for a NEGATIVE left operand of << (ISO C11
   6.5.7p4: E1 negative -> undefined). Both engines should agree on the code. */
int main(void) {
  int m = -1;
  int r = m << 1;
  return r & 1;
}
