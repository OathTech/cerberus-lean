/* audit K2 k2_puts_printf. gcc: "a\nb\nc\n". */
#include <stdio.h>
int main(void) { puts("a"); printf("b\n"); puts("c"); return 0; }
