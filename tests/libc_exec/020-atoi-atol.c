// 020: atoi/atol/atoll: leading whitespace and sign, trailing junk, empty
// string, and a 64-bit value through atol.
#include <stdio.h>
#include <stdlib.h>
int main(void) {
  return printf("%d %d %d %d %ld %lld\n", atoi("  -42abc"), atoi("+7"), atoi(""),
                atoi("\t\n 3 4"), atol("-9000000000"), atoll("123456789012"));
}
