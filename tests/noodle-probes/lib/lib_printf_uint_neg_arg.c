/* Corner: %u with the int argument -1 (not representable in unsigned int):
   UB under a strict reading of ISO C11 7.21.6.1p9; gcc prints 4294967295.
   Verdict-class control for lib_printf_hex_int_arg.c. */
#include <stdio.h>
int main(void) { printf("[%u]\n", -1); return 0; }
