struct P { int x, y; };
int f(struct P p) { return p.x + p.y; }
int main(void) {
  int *a = (int[]){1,2,3};
  int s = f((struct P){ .x = 4, .y = 5 });
  return a[2] + s;  /* 3 + 9 = 12 */
}
