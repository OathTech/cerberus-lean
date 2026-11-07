#include <stdio.h>

int main(void) { char b[4]; int n = snprintf(b, 4, "%*d", 8, 9); printf("%d:%s\n", n, b); return 0; }
