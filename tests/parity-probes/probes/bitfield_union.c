struct S { unsigned a:4; unsigned b:4; };
union U { struct S s; unsigned char raw; };
int main(void) {
  union U u;
  u.s.a = 3; u.s.b = 5;
  return u.s.a + u.s.b;  /* 8; raw read would be impl-defined */
}
