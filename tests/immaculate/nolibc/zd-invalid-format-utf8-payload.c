/* Bug hunt 2026-09-29 BUG-4 (record lean_frontend/docs/2026-09-29_bug-hunt-fixes-record.md §S4):
   the Invalid_format UB payload carries the format string's BYTES. The oracle prints the batch
   `ub:` field with %s (driver_ocaml.ml:134-138), i.e. those bytes raw; Lean printed each byte-carrier
   Char >= 0x80 UTF-8-encoded (c3 a9 became c3 83 c2 a9). %y is not a conversion (formatted.lem). */
#include <stdio.h>
int main(void) { printf("caf\xc3\xa9 %y", 1); return 0; }
