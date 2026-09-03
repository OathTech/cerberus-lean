/* Corner: reading an uninitialised automatic object whose address is never
   taken (ISO C11 6.3.2.1p2: UB). Verdict-class agreement probe. */
int main(void) {
  int x;
  return x & 0;
}
