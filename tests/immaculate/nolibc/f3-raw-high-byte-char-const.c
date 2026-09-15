// F3 (semantics-audit repairs D2, finding 3; RAW SOURCE BYTES c3 a9 in the literal are DELIBERATE — do not re-encode):
// a CHARACTER CONSTANT whose body is the raw two bytes c3 a9: decode_character_constant rejects a
// non-basic-source-set byte (oracle exit 125, uncaught Failure); Lean CerbDecode panic. gcc: multi-char
// constant, implementation-defined value (-w).
int main(void) { return 'é'; }
