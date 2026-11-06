/* three handlers, reverse registration order (7.22.4.4#3). gcc: "m321", 4. */
#include <stdio.h>
#include <stdlib.h>
void h1(void) { printf("1"); }
void h2(void) { printf("2"); }
void h3(void) { printf("3"); }
int main(void) { atexit(h1); atexit(h2); atexit(h3); printf("m"); return 4; }
