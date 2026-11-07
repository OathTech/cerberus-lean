/* FORK-PINNED (not gcc's line): the text of a null pointer under %p is implementation-defined (C17 7.21.6.1#8 p);
   the fork prints the memory model's `NULL(void)`, gcc `(nil)`. Pinned to the fork's own line, gcc's beside it in gcc.txt. */
#include <stdio.h>

int main(void) { printf("[%p]\n", (void *)0); return 0; }
