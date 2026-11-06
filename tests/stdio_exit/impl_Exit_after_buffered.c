/* FORK-PINNED (7.22.4.5#2, implementation-defined): _Exit runs no handler and flushes nothing; the shipped library wrote the first newline-terminated line through before switching stdout to full buffering, so "a\n" is seen and "b" lost; gcc with a pipe prints nothing (fully buffered from the start), $?=5. gcc on a terminal (glibc line-buffers stdout there): "a\n" = the fork's line, by reasoning (no pty in the sandbox; the operator can measure). */
#include <stdio.h>
#include <stdlib.h>
void h(void) { printf("h"); }
int main(void) { atexit(h); puts("a"); fputs("b", stdout); _Exit(5); }
