/* Corner: 12 levels of nested blocks each shadowing `x`; inner reads see
   the innermost, outer values survive (ISO C11 6.2.1p4). */
#include <stdio.h>
int main(void) {
  int x = 0, s = 0;
  { int x = 1; s += x; { int x = 2; s += x; { int x = 3; s += x; { int x = 4; s += x;
  { int x = 5; s += x; { int x = 6; s += x; { int x = 7; s += x; { int x = 8; s += x;
  { int x = 9; s += x; { int x = 10; s += x; { int x = 11; s += x; { int x = 12; s += x;
  } s += x; } s += x; } s += x; } s += x; } s += x; } s += x; } s += x; } s += x; } s += x; } s += x; } s += x; }
  printf("%d %d\n", s, x);   /* 78+66=144 0 */
  return 0;
}
