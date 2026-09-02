int main(void) {
  char a[100000] = {0};
  a[100000 - 1] = 7;
  return a[100000 - 1] + a[0];
}
