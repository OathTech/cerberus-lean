int main(void) {
  char a[10000];
  int i;
  for (i = 0; i < 10000; i++) a[i] = (char)i;
  return a[10000 - 1];
}
