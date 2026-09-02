int main(void) {
  char a[10000] = {0};
  a[10000 - 1] = 7;
  return a[10000 - 1] + a[0];
}
