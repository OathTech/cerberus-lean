/* FORK-PINNED (7.22.4.1#2): the shipped abort raises SIGABRT (the default handler prints "SIGABRT\n" on stderr) and _Exit(127); no handler, no flush; "a\n" went through before. gcc: SIGABRT, $?=134, stdout empty. */
#include <stdio.h>
#include <stdlib.h>
void h(void) { printf("h"); }
int main(void) { atexit(h); puts("a"); fputs("b", stdout); abort(); }
