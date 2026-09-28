// exhaustive/001: libc mode, compared EXHAUSTIVELY (oracle --mode=exhaustive,
// Lean without --first). The two operands of '+' are unsequenced function
// calls that each record their order; the execution set therefore holds
// both orders, and the libc calls after the sum (snprintf, strlen, printf)
// run in each. A single-trace run sees only one of the outcomes.
#include <stdio.h>
#include <string.h>
static int last = 0;
static int set(int v) { last = v; return v; }
int main(void) {
  int r = set(1) + set(2);
  char buf[16];
  snprintf(buf, sizeof buf, "%d-%d", r, last);
  printf("%s\n", buf);
  return (int)strlen(buf) * 10 + last;
}
