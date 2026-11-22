int k(int c) { switch (c) { case '\377': return 1; case '\200': return 2; default: return 0; } }
int main(void) {
  int a = k(255);
  int b = k(128);
  int c = k(-1);
  int d = k(-128);
  return a * 10 + b + (c * 10 + d) * 4;
}
