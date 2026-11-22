int main(void) {
  int r = 0;
  char c = '\377', a = 'a';
  signed char s = -1; unsigned char u = 255;
  if (c < 0) r += 1;
  if (c > a) r += 2;
  if (c == s) r += 4;
  if (c == u) r += 8;
  if (c < a) r += 16;
  if (c >= 128) r += 32;
  if ((c < 0) == (s < 0)) r += 64;
  return r;
}
