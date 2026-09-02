int main(void) {
  char a[10000000];
  a[10000000 - 1] = 7;
  return a[10000000 - 1];
}
