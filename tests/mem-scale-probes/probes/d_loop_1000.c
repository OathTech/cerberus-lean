int main(void) {
  char a[1000];
  int i;
  for (i = 0; i < 1000; i++) a[i] = (char)i;
  return a[1000 - 1];
}
