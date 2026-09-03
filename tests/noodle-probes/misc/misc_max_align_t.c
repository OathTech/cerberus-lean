/* Corner: sizeof/_Alignof(max_align_t) (ISO C11 7.19): gcc 32/16; the
   Cerberus impl's long double is 8 bytes (declared), so values may differ. */
#include <stddef.h>
#include <stdio.h>
int main(void) { printf("%d %d\n", (int)sizeof(max_align_t), (int)_Alignof(max_align_t)); return 0; }
