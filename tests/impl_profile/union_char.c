union u { char c; unsigned char uc; signed char sc; int i; };
int main(void) {
  int r = 0;
  union u x;
  x.i = 0;
  x.uc = 200;
  if (x.c > 0) r += 1;
  if (x.c == 200) r += 2;
  if (x.sc < 0) r += 4;
  x.c = (char)255;
  if (x.uc == 255) r += 8;
  if (x.c == x.sc) r += 16;
  if (x.c == x.uc) r += 32;
  return r;
}
