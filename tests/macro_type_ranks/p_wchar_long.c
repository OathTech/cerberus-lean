#include <stddef.h>
#include <stdio.h>
int main(void){ wchar_t w = 1; long l = (long)1 << 33;
  printf("%lld %lld %d\n", (long long)(w + l), (long long)(l + w), w < l); return 0; }
