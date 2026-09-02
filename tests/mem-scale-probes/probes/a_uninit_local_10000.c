int main(void) {
  char a[10000];
  a[10000 - 1] = 7;
  return a[10000 - 1];
}
