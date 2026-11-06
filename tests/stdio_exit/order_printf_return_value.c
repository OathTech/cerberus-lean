/* printf resolved to the library's own keeps its return value (7.21.6.3#3). gcc: "ab12|4\n", 4. */
#include <stdio.h>
int main(void) { int n = printf("%s%d", "ab", 12); fputs("|", stdout); printf("%d\n", n); return n; }
