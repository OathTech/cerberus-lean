// 024: every ctype.h classifier and both case mappings over all 256
// unsigned-char values plus EOF: per-class counts and a mapping checksum.
#include <ctype.h>
#include <stdio.h>
int main(void) {
  int n[12] = {0};
  unsigned sum = 0;
  for (int c = -1; c < 256; c++) {
    n[0] += !!isalnum(c); n[1] += !!isalpha(c); n[2] += !!isblank(c); n[3] += !!iscntrl(c);
    n[4] += !!isdigit(c); n[5] += !!isgraph(c); n[6] += !!islower(c); n[7] += !!isprint(c);
    n[8] += !!ispunct(c); n[9] += !!isspace(c); n[10] += !!isupper(c); n[11] += !!isxdigit(c);
    sum = sum * 7u + (unsigned)toupper(c) + 3u * (unsigned)tolower(c);
  }
  int r = 0;
  for (int i = 0; i < 12; i++) r += printf("%d ", n[i]);
  return r + printf("%u\n", sum);
}
