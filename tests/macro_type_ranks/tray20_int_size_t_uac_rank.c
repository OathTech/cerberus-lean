/* Corner: usual arithmetic conversions between size_t and int/char/short/
   unsigned int (ISO C11 6.3.1.8p1: the unsigned operand's rank >= the
   other's, so the other converts to size_t). Values above 2^32 expose any
   32-bit intermediate. gcc: 5000000001 10000000000 2500000001 5000000001
   5000000001 5000000001 0 5000000001 5000000001 */
#include <stddef.h>
#include <stdio.h>
int main(void) {
  size_t n = 5000000000; unsigned u = 1; char c = 1; short s = 1;
  printf("%llu %llu %llu ", (unsigned long long)(n + 1), (unsigned long long)(n * 2), (unsigned long long)(n / 2 + 1));
  printf("%llu %llu %llu ", (unsigned long long)(n + u), (unsigned long long)(u + n), (unsigned long long)(n + c));
  printf("%d %llu %llu\n", n == 705032704, (unsigned long long)(s + n), (unsigned long long)(1 + n));
  return 0;
}
