/* Corner: memset converts its value to unsigned char (ISO C11 7.24.6.1p2);
   memset(-1) over ints yields -1; size 0 is a no-op. */
#include <string.h>
#include <stdio.h>
int main(void) {
  int a[2] = {5, 6}; int b[2] = {7, 8}; int c = 9;
  memset(a, 0x101, sizeof a);
  memset(b, -1, sizeof b);
  memset(&c, 1, 0);
  printf("%d %d %d %d %d\n", a[0], a[1], b[0], b[1], c);   /* 16843009 16843009 -1 -1 9 */
  return 0;
}
