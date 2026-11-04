#include <stdio.h>
enum E { X = 5 }; int main(void) { enum E e = X; unsigned u = 4000000000u; long l = -1; printf("%d %d %d\n", (e - 6) < 0, (e + u) > 0, l < e); return 0; }
