/* FORK-PINNED: Specified(256) and the handler ran ("h\n"); gcc's $? is 0. */
#include <stdlib.h>
#include <stdio.h>
void h(void) { puts("h"); }
int main(void) { atexit(h); return 256; }
