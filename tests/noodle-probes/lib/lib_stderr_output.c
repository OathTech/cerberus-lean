/* Corner: fprintf(stderr) lands in the stderr field; fputs/fputc to stdout
   followed by fflush; return values (ISO C11 7.21.7). */
#include <stdio.h>
int main(void) {
  int a = fprintf(stderr, "err%d\n", 7);   /* 5 */
  int b = fputs("out", stdout);            /* >= 0 */
  int c = fputc('!', stdout);              /* 33 */
  fflush(stdout);
  printf(" %d %d %d\n", a, b >= 0, c);
  return 0;
}
