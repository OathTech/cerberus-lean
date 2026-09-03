/* Corner: goto into a block past a (non-VLA) declaration is legal; the
   jumped-over object is uninitialised but assigned before use
   (ISO C11 6.8.6.1p1). Labels have their own name space (6.2.3). */
#include <stdio.h>
int main(void) {
  int n = 0, x = 0;
  goto in;
  {
    int y = 100;      /* skipped */
  in:
    n++;
    if (n < 3) goto in;
  }
  x: x = 5;           /* label named like a variable */
  if (n == 3) { n = 10; goto x; }
  printf("%d %d\n", n, x);   /* 10 5 */
  return 0;
}
