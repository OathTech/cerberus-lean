/* Z2 probe (same site, are_compatible ailTypesAux.lem:792-796): int32_t* vs int*. */
#include <stdint.h>
int main(void) { int32_t x = 5; int *p = &x; return *p; }
