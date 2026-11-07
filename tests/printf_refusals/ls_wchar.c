#include <stdio.h>
#include <stddef.h>

int main(void) { wchar_t w[3]; w[0] = 97; w[1] = 98; w[2] = 0; printf("[%ls]\n", w); return 0; }
