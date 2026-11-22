int main(void) {
  int r = 0;
  _Atomic char a = (char)200;
  char b = a;
  if (b > 0) r += 1;
  if (a + 1 == 201) r += 2;
  if (a + 1 == -55) r += 4;
  a = (char)255;
  if (a == 255) r += 8;
  if (a == -1) r += 16;
  return r;
}
