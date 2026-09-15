// F3 (semantics-audit repairs D2, finding 3; RAW SOURCE BYTES c3 a9 in the literal are DELIBERATE — do not re-encode):
// as f3-raw-high-byte-int but the indexed byte is converted to unsigned char (gcc: 195). The decode
// of the raw byte happens first on both engines: oracle exit 125 (uncaught Failure), Lean panic.
int main(void) { return (unsigned char)"é"[0]; }
