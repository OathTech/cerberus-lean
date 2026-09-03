/* Corner: exit() from a nested call terminates with the given status; the
   stdout written without newline is flushed (ISO C11 7.22.4.4). */
#include <stdlib.h>
#include <stdio.h>
void deep(int n) { if (n == 0) { printf("deep"); exit(3); } deep(n - 1); }
int main(void) { deep(5); printf("never"); return 0; }
