#include <stdio.h>

int main(void) { int n = snprintf((char *)0, 0, "%d%d", 12, 34); printf("%d\n", n); return 0; }
