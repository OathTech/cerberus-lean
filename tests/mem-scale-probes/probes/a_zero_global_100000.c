char g[100000];
int main(void) {
  g[100000 - 1] = 7;
  return g[100000 - 1] + g[0];
}
