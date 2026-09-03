/* Corner: declarator syntax: array of function pointers, function returning
   a function pointer, pointer to function taking a function pointer
   (ISO C11 6.7.6.3). Sequenced. */
#include <stdio.h>
int inc(int x) { return x + 1; }
int dbl(int x) { return x * 2; }
int (*pick(int which))(int) { return which ? dbl : inc; }
int apply(int (*f)(int), int v) { return f(v); }
int main(void) {
  int (*tab[2])(int) = { inc, dbl };
  int (*(*pp)(int))(int) = pick;
  int r1 = tab[0](1), r2 = tab[1](5); int r3 = pick(1)(3); int r4 = apply(pp(0), 10);
  printf("%d %d %d %d %d\n", r1, r2, r3, r4, (int)sizeof tab);   /* 2 10 6 11 16 */
  return 0;
}
