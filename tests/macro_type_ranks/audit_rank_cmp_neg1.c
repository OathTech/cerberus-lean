#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
int main(void) { int m = -1; size_t z = 1; ptrdiff_t d = 1; uint32_t u32 = 1; int64_t i64 = 1; uint64_t u64 = 1; long l = 1;
  printf("%d %d %d %d %d %d %d\n", m < z, m < d, m < u32, m < i64, m < u64, -1L < u32, m < (unsigned)1); return 0; }
