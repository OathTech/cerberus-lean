struct s { char c; char d[2]; };
static char g = (char)250;
int main(void) {
  int r = 0;
  struct s x = { (char)200, { (char)130, 5 } };
  struct s y = x;
  if (y.c > 0) r += 1;
  if (y.d[0] == 130) r += 2;
  if (y.d[0] == -126) r += 4;
  if (g > 0) r += 8;
  g = (char)(g + 1);
  if (g == 251) r += 16;
  if (g == -5) r += 32;
  return r;
}
