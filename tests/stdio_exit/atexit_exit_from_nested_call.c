/* exit() from a nested call: the handler runs, the buffer is flushed, the status is 3. gcc: "deeph\n", 3. */
#include <stdio.h>
#include <stdlib.h>
void h(void) { puts("h"); }
void deep(int n) { if (n == 0) { fputs("deep", stdout); exit(3); } deep(n - 1); }
int main(void) { atexit(h); deep(3); puts("never"); return 0; }
