/* Corner: abort() after unflushed stdout: the model records the bytes
   written so far; native full-buffered stdout is lost (7.22.4.1). Verdict-
   shape agreement probe (oracle vs Lean). */
#include <stdlib.h>
#include <stdio.h>
int main(void) { printf("abc"); abort(); }
