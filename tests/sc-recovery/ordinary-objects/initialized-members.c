/* A whole aggregate initializer followed by ordered member reads. */
struct pair { int x; int y; };
int main(void) {
  struct pair p = {19, 23};
  return p.x + p.y;
}
