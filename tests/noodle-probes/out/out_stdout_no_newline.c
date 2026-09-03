/* Corner: stdout without a trailing newline at normal termination through
   the printf proxy is preserved (ISO C11 7.21.3p7 note on last line). */
#include <stdio.h>
int main(void) { printf("abc"); return 2; }
