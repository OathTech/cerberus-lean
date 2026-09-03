// S12: the escaped_char/decode round-trip inside formatted.lem's
// store_chars_in_array (every printf/snprintf-stored char goes through
// decode_character_constant(escaped_char c)).
// THREE-WAY (arc-14 S0/S1): gcc = 127; ORACLE = 87 (Char.escaped
// renders 127 as decimal "\127", decode's octal reader reads it back
// as 0o127 = 87 — silent corruption, upstream-tray candidate);
// Lean = 127 (hex \xNN round-trip is exact).
// EXPECTED: DIFF, Lean-right — ISO-fix register R2 (VALIDATION.md; code site
// CerbDecode.escaped_char, marker `-- ISO-fix register R2`; upstream tray 11).
// The row flips to MATCH and the entry RETIRES when upstream fixes tray 11.
#include <stdio.h>
int main(void) {
  char buf[8];
  snprintf(buf, 8, "%c", 127);
  return buf[0];
}
