/* bitfields: pack, read, write, signedness */
struct S { unsigned a:3; unsigned b:5; signed c:4; unsigned d:1; };
int main(void) {
  struct S s;
  s.a = 5; s.b = 21; s.c = -3; s.d = 1;
  s.a = s.a + 2;            /* 7 */
  s.c = s.c - 5;            /* -8 */
  return (s.a == 7) + 2*(s.b == 21) + 4*(s.c == -8) + 8*(s.d == 1);  /* expect 15 */
}
