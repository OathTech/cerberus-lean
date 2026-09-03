/* Corner: tentative definitions merge with the one real definition in a TU
   (ISO C11 6.9.2p2); extern incomplete array completed later (6.9.2p5). */
#include <stdio.h>
int x; int x = 5; int x;
extern int ext[];
static int first(void) { return ext[0]; }
int ext[] = {1, 2, 3};
int main(void) { printf("%d %d %d\n", x, first(), (int)sizeof ext); return 0; }   /* 5 1 12 */
