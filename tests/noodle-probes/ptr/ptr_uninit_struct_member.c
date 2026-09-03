/* Corner: a partially initialised struct local: reading the initialised
   member is fine, the other member is indeterminate but unread
   (ISO C11 6.7.9p10 does NOT apply: no initializer at all). */
int main(void) {
  struct S { int a; int b; } s;
  s.a = 7;
  struct S t = s;      /* copies an indeterminate member: defined (whole-object copy) */
  return t.a;
}
