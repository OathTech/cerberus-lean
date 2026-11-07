#include <stdio.h>

int main(void) { char b[32]; int n = snprintf(b, sizeof b, "%d-%s", 7, "x"); printf("%d:%s\n", n, b); return 0; }
