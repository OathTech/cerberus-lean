#include <stdio.h>

int main(void) { char b[4]; int n = snprintf(b, sizeof b, "%d", 123456); printf("%d:%s:%d\n", n, b, b[3] == 0); return 0; }
