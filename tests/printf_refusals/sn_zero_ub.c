#include <stdio.h>

int main(void) { int n = snprintf((char *)0, 0, "%d", 1.5); printf("%d\n", n); return 0; }
