#include <stdio.h>

int main(void) { int r = printf("hello\n"); printf("%d\n", r); int r2 = printf("[%*d][%.*s]\n", 4, 9, 2, "abc"); printf("%d\n", r2); return 0; }
