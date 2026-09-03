/* Corner: memcpy of a struct with padding, then reading the members from
   the copy (padding bytes are unspecified but never read) (ISO C11 6.2.6.1p6). */
#include <string.h>
struct S { char c; int i; char d; };
int main(void) {
  struct S a, b;
  a.c = 1; a.i = 300; a.d = 2;
  memcpy(&b, &a, sizeof a);
  return b.c + (b.i & 0xff) + b.d;   /* 1 + 44 + 2 = 47 */
}
