/* Corner: relational comparison of pointers to distinct objects is UB
   (ISO C11 6.5.8p5). Verdict-class agreement probe. */
int main(void) {
  int a, b;
  int *p = &a, *q = &b;
  return (p < q) ? 1 : 2;
}
