/* zero-discrepancy pin (2026-09-03, docs/2026-09-03_zero-discrepancy-design.md Z-36 (E2) — ISO-fix register R1).
   Origin: tests/noodle-probes/ptr/ptr_string_literals.c (verbatim body below the header).
   Pinned RED before the Z1 fix at the CURRENT Lean value (ORACLE_CRASH pair: oracle Failure(decode_character_constant ...) exit 125, Lean Specified(0) = gcc byte-for-byte); the fix
   commit re-records it — this row does NOT flip: it is the register-R1 Lean-right/oracle-wrong pin (tray 10 addendum); it flips to MATCH when upstream fixes tray 10 and the entry retires. The lane fails closed both ways. */
#include <stdio.h>
int main(void) {
  char *s = "a" "b";
  const char *t = "\x41" "B";       /* "AB" (hex escape ends at the literal boundary) */
  const char *o = "\1234";          /* octal 123 = 'S' then '4' */
  const char *e = "\n\t\\\"\'\?";
  printf("%d %d %d %d ", s[1], t[0], t[1], (int)sizeof("abc"));   /* 98 65 66 4 */
  printf("%d %d %d ", o[0], o[1], (int)sizeof("\1234"));            /* 83 52 3 */
  printf("%d %d %d %d %d %d ", e[0], e[1], e[2], e[3], e[4], e[5]); /* 10 9 92 34 39 63 */
  printf("%d %d\n", "abc"[3], (int)sizeof("a\0b"));                 /* 0 4 */
  return 0;
}
