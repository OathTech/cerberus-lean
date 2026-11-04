#include <stddef.h>
#include <stdio.h>
int main(void) { size_t n = 5000000000; int i = 7; int c = 1; size_t r = c ? n : i; size_t r2 = c ? i : n; printf("%llu %llu %d\n", (unsigned long long)r, (unsigned long long)r2, sizeof(c ? n : i) == sizeof(size_t)); return 0; }
