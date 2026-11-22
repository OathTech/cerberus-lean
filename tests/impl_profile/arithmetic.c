int main(void) {
  int r = 0;
  char c = 100, d = 100;
  char e = (char)(c + d);
  if (e == 200) r += 1;
  if (e == -56) r += 2;
  char f = 0; f -= 1;
  if (f > 0) r += 4;
  char g = '\200'; g >>= 1;
  if (g == 64) r += 8;
  if (g == -64) r += 16;
  char h = 127; h++;
  if (h == 128) r += 32;
  if (h == -128) r += 64;
  return r;
}
