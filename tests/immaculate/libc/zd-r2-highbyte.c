// ISO-fix register R2, widened scope (2026-09-29, bug hunt K-1): the same
// escaped_char/decode round-trip corrupts every stored byte >= 128. Here
// 0xC8 = 200 is rendered "\200" and read back as octal 0o200 = 128.
// gcc = 200; ORACLE = 128; Lean = 200. EXPECTED: DIFF, Lean-right (R2).
#include <stdio.h>
int main(void) {
  char buf[8];
  snprintf(buf, 8, "%s", "\xc8");
  return (unsigned char)buf[0];
}
