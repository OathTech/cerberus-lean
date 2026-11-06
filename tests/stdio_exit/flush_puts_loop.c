/* audit K2 k2_puts_in_loop. gcc: "x\nx\nx\nx\n". */
#include <stdio.h>
int main(void) { for (int i = 0; i < 4; i++) puts("x"); return 0; }
