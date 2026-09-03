/* Corner: _Generic selection incl. default and qualifier stripping of the
   controlling expression (6.5.1.1), _Static_assert (6.7.10), _Alignof. */
#include <stdio.h>
#define T(x) _Generic((x), char: 1, int: 2, double: 3, char*: 4, default: 9)
_Static_assert(sizeof(int) == 4, "int is 4 bytes");
int main(void) {
  const int ci = 0; char c = 0; char *p = 0; long l = 0;
  _Static_assert(_Alignof(long) == 8, "long align");
  printf("%d %d %d %d %d %d\n", T(ci), T(c), T(1.0), T(p), T(l), T('a'));   /* 2 1 3 4 9 2 */
  return 0;
}
