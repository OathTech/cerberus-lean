int main(void) {
  int r = 0;
  char c = (char)100;
  double d = c;
  if (d == 100.0) r += 1;
  char h = '\377';
  double e = h;
  if (e == 255.0) r += 2;
  if (e == -1.0) r += 4;
  float f = (float)h;
  if (f > 0.0f) r += 8;
  double g = 100.5;
  char k = (char)g;
  if (k == 100) r += 16;
  if ((double)(char)'\200' == 128.0) r += 32;
  return r;
}
