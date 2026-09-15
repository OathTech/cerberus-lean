// Escape sweep (semantics-audit repairs D2): a \0 INSIDE a literal is a byte like any other —
// sizeof("ab\0cd") = 6 (five bytes + NUL), s[2] = 0, s[3] = 'c' = 99: 6*10 + 0 + 99 = 159.
int main(void) {
  const char *s = "ab\0cd";
  return sizeof("ab\0cd") * 10 + (unsigned char)s[2] + (unsigned char)s[3];
}
