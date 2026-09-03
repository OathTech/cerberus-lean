/* Corner: getchar() on an empty stdin returns EOF (ISO C11 7.21.7.6).
   CerbFS is a declared model boundary (fail-closed): verdict-class
   agreement probe (libc mode). */
#include <stdio.h>
int main(void) { int c = getchar(); return c == EOF ? 1 : 2; }
