#include <stdio.h>
#include <stdint.h>

int main(void) { printf("[%ji][%jo][%jx][%jX]\n", (intmax_t)9, (uintmax_t)8, (uintmax_t)255, (uintmax_t)255); return 0; }
