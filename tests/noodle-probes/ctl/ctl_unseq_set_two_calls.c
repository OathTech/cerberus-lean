/* Corner: unsequenced evaluation of two calls with side effects on a
   global: exhaustive mode must produce exactly the two outcomes
   "0 1" and "1 0" (ISO C11 6.5.2.2p10 indeterminately sequenced). */
#include <stdio.h>
int c = 0;
int f(void) { return c++; }
int g(void) { return c++; }
int main(void) { printf("%d %d\n", f(), g()); return 0; }
