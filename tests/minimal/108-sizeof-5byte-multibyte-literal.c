// RAW SOURCE BYTES in the string literal below are DELIBERATE (semantics-audit repairs D2, finding 3: the byte-preserving Cabs bridge) — do NOT re-encode or escape them.
// The literal is the five bytes c3 a9 e2 82 ac (UTF-8 of U+00E9 U+20AC); sizeof = 5 + NUL = 6.
int main(void) { return sizeof("é€"); }
