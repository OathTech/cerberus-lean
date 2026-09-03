/* Corner: default argument promotions for unprototyped-style calls vs
   prototyped narrow parameters; char/short parameters receive converted
   values (ISO C11 6.5.2.2p6-7). */
#include <stdio.h>
int narrow(signed char c, unsigned short s) { return c + s; }
int proto(int, char);
int proto(int a, char b) { return a - b; }
int main(void) {
  int r1 = narrow(300, 70000);   /* 44 + 4464 */
  int r2 = proto(10, 300);       /* 10 - 44 */
  printf("%d %d\n", r1, r2);     /* 4508 -34 */
  return 0;
}
