#include <stdio.h>

int main(void) { char b[32]; int n = snprintf(b, sizeof b, "%e", 3.5); printf("%d:%s\n", n, b); return 0; }
