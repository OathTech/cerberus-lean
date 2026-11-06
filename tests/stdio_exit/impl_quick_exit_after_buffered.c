/* FORK-PINNED (7.22.4.7#3 returns through _Exit; 7.22.4.5#2): the at_quick_exit handlers run in reverse ("q2q1"), the atexit handler does not, nothing is flushed; "a\n" went through before. gcc: nothing, 6. */
#include <stdio.h>
#include <stdlib.h>
void h(void) { printf("h"); }
void q1(void) { printf("q1"); }
void q2(void) { printf("q2"); }
int main(void) { atexit(h); at_quick_exit(q1); at_quick_exit(q2); puts("a"); fputs("b", stdout); quick_exit(6); }
