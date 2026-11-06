/* UB (7.22.4.4#3: exit called from a handler); pinned to the SHIPPED LIBRARY's (musl's) text, not a fork reading: the nested exit continues with the remaining handlers, then _Exit(9). gcc/glibc the same: "m321", 9. */
#include <stdio.h>
#include <stdlib.h>
void h1(void) { printf("1"); }
void h2(void) { printf("2"); exit(9); }
void h3(void) { printf("3"); }
int main(void) { atexit(h1); atexit(h2); atexit(h3); printf("m"); return 4; }
