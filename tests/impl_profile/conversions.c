int main(void) {
  int r = 0;
  char c = (char)200;
  if (c > 0) r += 1;
  if ((int)c == 200) r += 2;
  if ((int)c == -56) r += 4;
  char d = (char)-1;
  if (d == 255) r += 8;
  if (d == -1) r += 16;
  unsigned u = (unsigned)(char)-1;
  if (u == 255u) r += 32;
  long l = (long)(char)128;
  if (l == 128) r += 64;
  return r;
}
