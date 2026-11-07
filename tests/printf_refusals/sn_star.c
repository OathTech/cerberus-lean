#include <stdio.h>

int main(void) { char b[16]; int n = snprintf(b, sizeof b, "[%*d][%.*s]", 4, 9, 2, "abc"); printf("%d:%s\n", n, b); return 0; }
