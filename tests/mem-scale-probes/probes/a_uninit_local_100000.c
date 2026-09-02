int main(void) {
  char a[100000];
  a[100000 - 1] = 7;
  return a[100000 - 1];
}
