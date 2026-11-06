/* FORK-PINNED (7.22.4.7#3 returns through _Exit; 7.22.4.5#2): the at_quick_exit handlers run in reverse ("q2q1"), the atexit handler does not, nothing is flushed AT TERMINATION; "a\n" went through before, and the pending "b" went out when the first handler's printf (the library's, which flushes the stream's pending buffer before writing through) ran — the fork's write-through printf, not a flush at termination. gcc with a pipe: nothing, 6. gcc on a terminal: "a\n" only (glibc's printf in the handlers appends "q2q1" to the buffer, which _Exit drops) -- NOT the fork's line: the fork's library printf writes through, by reasoning (no pty in the sandbox). */
#include <stdio.h>
#include <stdlib.h>
void h(void) { printf("h"); }
void q1(void) { printf("q1"); }
void q2(void) { printf("q2"); }
int main(void) { atexit(h); at_quick_exit(q1); at_quick_exit(q2); puts("a"); fputs("b", stdout); quick_exit(6); }
