int f(int n) {
  int x = 0;
  if (n > 0) x = f(n-1);
  goto increment;
  do { increment: x++; if (x < 3) goto increment; } while (0);
  return x;
}
int g(int *p) { *p += 1; *p += 2; return *p; }
int main(void) { int y = 0; return f(2) + g(&y) != 8; }
