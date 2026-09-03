/* Corner: ?: in the OTHER integer-constant-expression contexts — enum
   constant, array size, case label (ISO C11 6.6p6). CONTROL for
   elab_const_expr_ternary_init.c: all engines accept. */
enum { E = 1 ? 2 : 3 };
int main(void) {
  int arr[1 ? 2 : 3];
  switch (E) { case (1 ? 2 : 3): return (int)sizeof arr + E; }   /* 8 + 2 */
  return 0;
}
