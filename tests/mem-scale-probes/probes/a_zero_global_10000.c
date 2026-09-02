char g[10000];
int main(void) {
  g[10000 - 1] = 7;
  return g[10000 - 1] + g[0];
}
