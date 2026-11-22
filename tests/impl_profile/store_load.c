int main(void) {
  int r = 0;
  char c = (char)200;
  char *p = &c;
  if (*p > 0) r += 1;
  *p = (char)255;
  if (c == 255) r += 2;
  if (c == -1) r += 4;
  unsigned char u = 200;
  char *q = (char *)&u;
  if (*q > 0) r += 8;
  if (*q == 200) r += 16;
  char a[3] = { (char)128, (char)129, (char)255 };
  int s = a[0] + a[1] + a[2];
  if (s == 512) r += 32;
  if (s == -256) r += 64;
  return r;
}
