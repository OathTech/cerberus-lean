#include <stddef.h>
int main(void){ return _Generic((size_t)0, unsigned long: 1, default: 2); }
