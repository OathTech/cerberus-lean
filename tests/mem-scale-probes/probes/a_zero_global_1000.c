char g[1000];
int main(void) {
  g[1000 - 1] = 7;
  return g[1000 - 1] + g[0];
}
