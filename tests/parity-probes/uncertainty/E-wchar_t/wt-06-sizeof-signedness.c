#include <stddef.h>
int main(void){ return (int)sizeof(wchar_t) + 10*((wchar_t)-1 < 0); }
