/* Corner: atexit handler runs when main calls exit() (ISO C11 7.22.4.4p3).
   CONTROL for lib_atexit_order.c (return from main). gcc: "m1", exit 4. */
#include <stdlib.h>
#include <stdio.h>
void h1(void) { printf("1"); }
int main(void) { atexit(h1); printf("m"); exit(4); }
