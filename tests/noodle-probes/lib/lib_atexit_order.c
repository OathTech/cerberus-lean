/* Corner: atexit handlers run in reverse registration order at exit, after
   main returns; stdout flushed (ISO C11 7.22.4.4, 7.22.4.3). */
#include <stdlib.h>
#include <stdio.h>
void h1(void) { printf("1"); }
void h2(void) { printf("2"); }
int main(void) { atexit(h1); atexit(h2); printf("m"); return 4; }   /* "m21", exit 4 */
