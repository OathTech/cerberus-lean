#include <stdio.h>
#include <stdint.h>

int main(void) { printf("[%*ld][%.*lld][%*zu][%*jd]\n", 5, 7L, 3, 7LL, 4, sizeof(int), 4, (intmax_t)7); return 0; }
