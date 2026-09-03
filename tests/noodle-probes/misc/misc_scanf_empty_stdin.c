/* Corner: scanf("%d") on empty stdin returns EOF and leaves the target
   unchanged (ISO C11 7.21.6.4). libc mode; CerbFS boundary. */
#include <stdio.h>
int main(void) { int x = 7; int r = scanf("%d", &x); return (r == EOF) * 10 + x; }   /* 17 */
