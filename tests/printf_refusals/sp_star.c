#include <stdio.h>

int main(void) { char b[32]; int n = sprintf(b, "[%*d]", 4, 9); printf("%d:%s\n", n, b); return 0; }
