/* zero-discrepancy Z3 probe (2026-09-05, charter row Z-28 / detective RC-2; record
   docs/2026-09-05_zero-discrepancy-Z3-record.md). libc-mode allocation-address
   ORDER: prints (long)&g for five program globals of different alignments (one
   depending on another: p1 = &i1), a libc global reachable through <unistd.h>
   (optind) and a local. Addresses are values under PVI, so the whole stdout line
   is behaviour. Pinned RED before the Z3 fix (Lean allocated every libc global
   first, in name-hash order; the oracle orders the linked globals by
   Core_linking.merge_globs' topological min-(digest, number) choice — the
   program's globals interleave among the libc TUs' by the program file's MD5).
   gcc is not meaningful for the absolute addresses (its return value 0 is:
   alignment + the dependent pointer). */
#include <stdio.h>
#include <unistd.h>
struct S { char c; double d; } s1;
char c1 = 'a';
int i1 = 1;
int *p1 = &i1;
long l1 = 2;
int main(void) {
  int loc = 3;
  printf("s1=%ld c1=%ld i1=%ld p1=%ld l1=%ld optind=%ld\n",
    (long)&s1, (long)&c1, (long)&i1, (long)&p1, (long)&l1, (long)&optind);
  printf("loc=%ld\n", (long)&loc);
  return (int)((long)&i1 % 4) + (int)((long)&s1 % 8) + (*p1 == 1 ? 0 : 1);
}
