// RAW SOURCE BYTES in the string literal below are DELIBERATE (semantics-audit repairs D2, finding 3: the byte-preserving Cabs bridge) — do NOT re-encode or escape them.
// The literal is the two bytes c3 a9 (UTF-8 of U+00E9); sizeof counts bytes + NUL = 3.
// The bytes are never DECODED (no character value is formed), so the oracle succeeds: Specified(3).
int main(void) { return sizeof("é"); }
