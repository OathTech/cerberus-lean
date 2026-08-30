/* bitfield assignment wraps modulo width (unsigned) */
struct S { unsigned a:3; };
int main(void) {
  struct S s;
  s.a = 260;   /* 260 mod 8 = 4 */
  return s.a;  /* expect 4 */
}
