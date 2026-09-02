int main(void) {
  char a[100000];
  int i;
  for (i = 0; i < 100000; i++) a[i] = (char)i;
  return a[100000 - 1];
}
