/* audit K2 k2_fputs_nl_twice. gcc: "a\nb\n". */
#include <stdio.h>
int main(void) { fputs("a\n", stdout); fputs("b\n", stdout); return 0; }
