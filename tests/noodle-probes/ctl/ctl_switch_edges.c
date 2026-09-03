/* Corner: switch on negative values, on char (signed), case labels with
   negative/escape constants, default not last, fallthrough, nested switch
   (ISO C11 6.8.4.2). Sequenced calls. */
#include <stdio.h>
int cls(int v) {
  switch (v) {
    case -1: return 1;
    default: return 9;
    case 0: case 1: return 2;
    case 200: return 3;
  }
}
int main(void) {
  char c = 200; _Bool b = 1; int out = 0;
  switch (c) { case 200: out = 1; break; case -56: out = 2; break; default: out = 3; }
  int f = 0;
  switch (2) { case 1: f += 1; case 2: f += 10; case 3: f += 100; break; case 4: f += 1000; }
  int n = 0;
  switch (b) { case 1: switch (out) { case 2: n = 5; break; default: n = 6; } break; case 0: n = 7; }
  int c1 = cls(-1), c2 = cls(0), c3 = cls(1), c4 = cls(200), c5 = cls(50);
  printf("%d %d %d %d %d %d %d\n", c1, c2, c3, c4, c5, out, f);   /* 1 2 2 3 9 2 110 */
  printf("%d\n", n);
  return 0;
}
