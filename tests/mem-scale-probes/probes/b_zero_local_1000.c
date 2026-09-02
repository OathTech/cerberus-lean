int main(void) {
  char a[1000] = {0};
  a[1000 - 1] = 7;
  return a[1000 - 1] + a[0];
}
