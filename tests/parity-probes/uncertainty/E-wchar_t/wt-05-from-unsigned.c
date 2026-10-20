#include <stddef.h>
int main(void){ unsigned x = 0xffffffffu; wchar_t w = x; return w < 0; }
