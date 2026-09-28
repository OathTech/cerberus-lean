// 040: atexit handlers run in reverse registration order at exit, after
// main's output. The runtime libc stores each handler as an integer
// (stdlib.c:194-199), so this also pins the function-pointer <-> integer
// round trip (named deviation N1 serves it; a refusal broke it, 2026-09-28).
#include <stdio.h>
#include <stdlib.h>
void bye(void) { printf("bye\n"); }
void first(void) { printf("first-registered\n"); }
int main(void) { atexit(first); atexit(bye); printf("main\n"); exit(7); }
