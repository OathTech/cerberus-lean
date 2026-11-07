#include <stdio.h>

int main(void) { int n = 0; printf("ab%n\n", &n); printf("%d\n", n); return 0; }
