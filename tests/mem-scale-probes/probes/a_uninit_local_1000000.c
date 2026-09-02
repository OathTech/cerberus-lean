int main(void) {
  char a[1000000];
  a[1000000 - 1] = 7;
  return a[1000000 - 1];
}
