/* Corner: a static local shared across recursive activations; block-scope
   static initialised once (ISO C11 6.2.4p3). */
#include <stdio.h>
int depth(int n) { static int calls = 0; calls++; if (n) depth(n - 1); return calls; }
int main(void) { int a = depth(3); int b = depth(0); printf("%d %d\n", a, b); return 0; }   /* 4 5 */
