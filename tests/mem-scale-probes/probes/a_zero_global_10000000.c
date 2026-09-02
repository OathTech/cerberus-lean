char g[10000000];
int main(void) {
  g[10000000 - 1] = 7;
  return g[10000000 - 1] + g[0];
}
