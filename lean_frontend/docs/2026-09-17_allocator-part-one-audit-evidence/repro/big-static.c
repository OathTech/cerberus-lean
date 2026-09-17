/* AUDITOR: ONE global of 2^48 bytes = last_address + 1, 64-aligned: z = -1, pristine rounds to z' = 62 and SUCCEEDS. */
#include <stdint.h>
_Alignas(64) static char big[0x1000000000000ULL];
int main(void) { return (int)((uintptr_t)big & 0xff); }
