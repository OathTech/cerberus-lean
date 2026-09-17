#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
int main(void) { printf("sizeof(size_t)=%d sizeof(uintptr_t)=%d sizeof(void*)=%d sizeof(long)=%d SIZE_MAX=%llu\n", (int)sizeof(size_t), (int)sizeof(uintptr_t), (int)sizeof(void*), (int)sizeof(long), (unsigned long long)SIZE_MAX); return 0; }
