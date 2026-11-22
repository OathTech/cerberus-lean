static int widen(char c) { return c; }
static char narrow(int n) { return (char)n; }
static char pass(char c) { return c; }
int main(void) {
  int r = 0;
  if (widen((char)200) == 200) r += 1;
  if (widen((char)200) == -56) r += 2;
  if (narrow(255) > 0) r += 4;
  if (narrow(128) == 128) r += 8;
  if (pass(narrow(250)) + 1 == 251) r += 16;
  char c = narrow(129);
  if (widen(c) < 0) r += 32;
  return r;
}
