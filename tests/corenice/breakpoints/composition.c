/* Source-composition witness: the marked block join after bump has x == 1,
   before the next statement makes x == 3. Loop-body joins expose x == 4,5,6. */
static void bump(int *p) { *p = *p + 1; }
int main(void) {
  int x = 0;
  bump(&x);
  x = x + 2;
  while (x < 6) {
    bump(&x);
  }
  return x;
}
