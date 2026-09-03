/* Corner: reading a union member wider than the last-written member: the
   extra bytes are unspecified (ISO C11 6.2.6.1p7). Verdict-class agreement
   probe: both engines should classify identically (unspecified vs UB). */
int main(void) {
  union { char c; int i; } u;
  u.c = 1;
  return u.i & 0xff;
}
