// 017: memmove with overlapping ranges in both directions (libc C, byte by
// byte); memchr with a byte >= 0x80 and a miss.
#include <stdio.h>
#include <string.h>
int main(void) {
  char a[] = "0123456789", b[] = "0123456789";
  memmove(a + 2, a, 5);      /* forward overlap */
  memmove(b, b + 3, 5);      /* backward overlap */
  unsigned char u[4] = {1, 0xfe, 3, 0xfe};
  unsigned char *p = memchr(u, 0xfe, 4);
  void *miss = memchr(u, 7, 4);
  return printf("%s %s %d %d\n", a, b, (int)(p - u), miss == NULL);
}
