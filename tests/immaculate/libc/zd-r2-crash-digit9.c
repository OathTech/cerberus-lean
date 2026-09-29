// ISO-fix register R2, widened scope (2026-09-29, bug hunt K-1): a byte whose
// decimal escape contains a 9 is not an octal constant, so the oracle's
// decode_character_constant fails ("started like an octal constant, but
// failed: 199") — an uncaught exception, rc 125. This hits 0xC3 = 195, the
// usual UTF-8 lead byte, so Latin-1 text through sprintf("%s") crashes it.
// gcc = 199; ORACLE crashes; Lean = 199. EXPECTED: ORACLE_CRASH, Lean-right (R2).
#include <stdio.h>
int main(void) {
  char buf[8];
  snprintf(buf, 8, "%s", "\xc7");
  return (unsigned char)buf[0];
}
