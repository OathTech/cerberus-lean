#include <stdio.h>
#include <stdint.h>
int main(void) {
  intptr_t a = 4294967301ULL;
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(+a), (unsigned long long)(-a), (unsigned long long)(~a), (unsigned long long)(a << 1), (unsigned long long)(a >> 1), (unsigned long long)(1 << (a & 3)), (unsigned long long)sizeof(+a), (unsigned long long)sizeof(a + 1));
  printf("T%d %d %d %d %d\n", _Generic((+a), _Bool: 1, char: 2, signed char: 3, unsigned char: 4, short: 5, unsigned short: 6, int: 7, unsigned: 8, long: 9, unsigned long: 10, long long: 11, unsigned long long: 12, default: 0), _Generic((-a), _Bool: 1, char: 2, signed char: 3, unsigned char: 4, short: 5, unsigned short: 6, int: 7, unsigned: 8, long: 9, unsigned long: 10, long long: 11, unsigned long long: 12, default: 0), _Generic((~a), _Bool: 1, char: 2, signed char: 3, unsigned char: 4, short: 5, unsigned short: 6, int: 7, unsigned: 8, long: 9, unsigned long: 10, long long: 11, unsigned long long: 12, default: 0), _Generic((a << 1), _Bool: 1, char: 2, signed char: 3, unsigned char: 4, short: 5, unsigned short: 6, int: 7, unsigned: 8, long: 9, unsigned long: 10, long long: 11, unsigned long long: 12, default: 0), _Generic((a + 1), _Bool: 1, char: 2, signed char: 3, unsigned char: 4, short: 5, unsigned short: 6, int: 7, unsigned: 8, long: 9, unsigned long: 10, long long: 11, unsigned long long: 12, default: 0));
  return 0;
}
