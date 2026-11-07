#include <stdio.h>

int main(void) { char b[32]; int n = sprintf(b, "[%5d][%-5d]", 42, 42); printf("%d:%s\n", n, b); return 0; }
