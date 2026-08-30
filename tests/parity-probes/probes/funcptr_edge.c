/* function-pointer edges, sequenced (unsequenced multi-call version
   explodes exhaustive interleavings on BOTH engines) */
int add(int a, int b) { return a + b; }
int apply(int (*op)(int,int), int a, int b) { return op(a, b); }
int main(void) {
  int (*p)(int,int) = &add;
  int (*q)(int,int) = add;      /* decay */
  void *v = 0;
  int r = apply(p, 1, 2);
  r += apply(q, 3, 4);
  r += (*p)(5, 6);
  r += p(7, 8);
  return r + (v == 0);  /* 3+7+11+15+1 = 37 */
}
