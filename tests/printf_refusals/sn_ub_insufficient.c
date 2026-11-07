#include <stdio.h>

int main(void) { char b[8]; int n = snprintf(b, 8, "%d"); printf("%d\n", n); return 0; }
