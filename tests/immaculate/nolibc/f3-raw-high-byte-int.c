// F3 (semantics-audit repairs D2, finding 3; RAW SOURCE BYTES c3 a9 in the literal are DELIBERATE — do not re-encode):
// a raw byte >= 0x80 MATERIALISED (indexed) is DECODED: the oracle's decode.ml:199-200 failwiths
// (uncaught Failure "decode_character_constant: invalid char constant", exit 125); Lean mirrors the table
// (CerbDecode) with a panic! — the same fail-stop class under LEAN_ABORT_ON_PANIC=1. gcc: (char)0xC3 = -61.
int main(void) { return "é"[0]; }
