int add(int a, int b) { return a + b; }
int apply(int (*op)(int,int), int a, int b) { return op(a, b); }
int main(void) {
  return apply(add, 1, 2);
}
