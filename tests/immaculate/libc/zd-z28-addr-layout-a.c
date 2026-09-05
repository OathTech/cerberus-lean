/* zero-discrepancy Z3 pin (2026-09-05, charter row Z-28; record docs/2026-09-05_zero-discrepancy-Z3-record.md).
   Digest-sensitivity PAIR (a/b): the two files are the same program and differ only in this
   comment line, so their MD5 digests differ — and with them the position of the program's
   globals among the libc TUs' globals in the oracle's linked order (merge_globs' min-(digest,
   number) topological choice). Both must MATCH after the Z3 fix, at DIFFERENT addresses.
   Pinned RED before the fix. This is file A. */
#include <stdio.h>
struct S { char c; double d; } s1;
char c1 = 'a';
int i1 = 1;
int *p1 = &i1;
int main(void) {
  printf("s1=%ld c1=%ld i1=%ld p1=%ld\n", (long)&s1, (long)&c1, (long)&i1, (long)&p1);
  return 0;
}
