struct b { char f : 4; char g : 8; };
int main(void) {
  struct b x;
  x.f = 15; x.g = (char)200;
  int r = 0;
  if (x.f == 15) r += 1;
  if (x.f == -1) r += 2;
  if (x.g > 0) r += 4;
  return r;
}
