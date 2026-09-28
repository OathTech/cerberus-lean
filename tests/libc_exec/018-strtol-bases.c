// 018: strtol/strtoul: bases 10, 16 (with 0x), 0 (octal and hex detection),
// 36, sign, leading whitespace, end-pointer positions, no digits (endptr ==
// str), and strtoul("-1") wrapping to ULONG_MAX.
#include <stdio.h>
#include <stdlib.h>
int main(void) {
  char *e1, *e2, *e3, *e4;
  const char *s4 = "  +xyz";
  long a = strtol("  -1234xyz", &e1, 10);
  long b = strtol("0x1F", &e2, 16);
  long c = strtol("017", 0, 0), d = strtol("0x10", 0, 0), f = strtol("zz", 0, 36);
  long g = strtol(s4, &e4, 10);
  unsigned long u = strtoul("-1", &e3, 10);
  return printf("%ld %ld %ld %ld %ld %ld %lu %s|%d|%d|%d\n", a, b, c, d, f, g, u, e1,
                (int)(*e2), (int)(e3[0]), e4 == s4);
}
