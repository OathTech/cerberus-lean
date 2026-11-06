/* audit K2 k2_putchar_many_nl. gcc: "A\nB\nC\n". */
#include <stdio.h>
int main(void) { putchar(65); putchar(10); putchar(66); putchar(10); putchar(67); putchar(10); return 0; }
