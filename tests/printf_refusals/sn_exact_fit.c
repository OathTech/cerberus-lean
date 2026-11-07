#include <stdio.h>

int main(void) { char b[6]; int n = snprintf(b, 6, "%s", "hello"); printf("%d:%s\n", n, b); return 0; }
