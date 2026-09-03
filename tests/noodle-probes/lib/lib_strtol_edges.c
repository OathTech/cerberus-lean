/* Corner: strtol/strtoul/atoi edge cases: leading space and sign, endptr,
   base 16 with 0x, base 0 octal, no digits, overflow clamps to LONG_MAX
   with errno ERANGE, strtoul of "-1", base 36 (ISO C11 7.22.1.4). Sequenced. */
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <limits.h>
int main(void) {
  char *end;
  long a = strtol("  -42xyz", &end, 10);    int ea = *end;        /* -42 'x' */
  long b = strtol("0x1A", 0, 16);                                 /* 26 */
  long c = strtol("010", 0, 0);                                   /* 8 */
  long d = strtol("", &end, 10);            int ed = (*end == 0); /* 0 1 */
  errno = 0;
  long e = strtol("99999999999999999999", 0, 10); int ee = (errno == ERANGE); /* LONG_MAX 1 */
  unsigned long f = strtoul("-1", 0, 10);                         /* ULONG_MAX */
  int g = atoi("+7");                                             /* 7 */
  long h = strtol("z", 0, 36);                                    /* 35 */
  int emax = e == LONG_MAX, fmax = f == ULONG_MAX;
  printf("%ld %d %ld %ld %ld %d %d %d %d %d %ld\n", a, ea, b, c, d, ed, emax, ee, fmax, g, h);
  return 0;
}
