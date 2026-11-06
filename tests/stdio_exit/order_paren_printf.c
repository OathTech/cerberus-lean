/* the identifier in parentheses, (printf)(...): with the library linked every form of the identifier resolves to the library's printf (M1c: the proxy substitution is withheld), ordered with the buffer. gcc: "bc\n". */
#include <stdio.h>
int main(void) { fputs("b", stdout); (printf)("c\n"); return 0; }
