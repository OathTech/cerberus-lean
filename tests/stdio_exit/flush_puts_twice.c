/* audit K2 k2_puts_nl_twice shape: the second line was lost (stdout fully buffered after the first write). gcc: "a\nb\n". */
#include <stdio.h>
int main(void) { puts("a"); puts("b"); return 0; }
