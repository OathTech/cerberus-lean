#include <stdio.h>
enum E { A = 1, B = 2 };
int main(void){ enum E e = B; int i = -3; unsigned long ul = (unsigned long)1 << 33;
  printf("%d %d %llu %d\n", e + i < 0, i < e, (unsigned long long)(e + ul), _Generic(+e, int: 1, unsigned: 2, default: 3)); return 0; }
