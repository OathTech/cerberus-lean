/* registered in a nested function, run at return from main. gcc: "m\nh\n". */
#include <stdio.h>
#include <stdlib.h>
void h(void) { puts("h"); }
void reg(void) { atexit(h); }
int main(void) { reg(); puts("m"); return 0; }
