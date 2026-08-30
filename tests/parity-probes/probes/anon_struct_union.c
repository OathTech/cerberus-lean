struct S {
  int tag;
  union {
    struct { int x, y; };
    long l;
  };
};
int main(void) {
  struct S s;
  s.tag = 1; s.x = 20; s.y = 22;
  return s.x + s.y;  /* 42 */
}
