/* Corner: struct assignment and array-member copy, struct passed and
   returned by value, nested struct member assignment (ISO C11 6.5.16.1p2).
   Sequenced statements (the unsequenced-call form enumerates 67,650
   traces on both engines). */
#include <stdio.h>
struct In { int v[3]; char tag; };
struct Out { struct In in; short s; };
struct Out mk(int k) { struct Out o; o.in.v[0] = k; o.in.v[1] = k+1; o.in.v[2] = k+2; o.in.tag = 'x'; o.s = -k; return o; }
int sum(struct Out o) { return o.in.v[0] + o.in.v[1] + o.in.v[2] + o.in.tag + o.s; }
int main(void) {
  struct Out a = mk(5), b;
  b = a;
  b.in.v[1] = 100;
  int sa = sum(a); int sb = sum(b);
  printf("%d %d %d %d\n", sa, sb, a.in.v[1], b.in.tag);  /* 133 227 6 120 */
  return 0;
}
