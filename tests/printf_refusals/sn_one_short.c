#include <stdio.h>

int main(void) { char b[5]; int n = snprintf(b, 5, "%s", "hello"); printf("%d:%s\n", n, b); return 0; }
