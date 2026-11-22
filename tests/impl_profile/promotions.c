int main(void) {
  int r = 0;
  char c = '\360';
  if (c + 1 == 241) r += 1;
  if (c + 1 == -15) r += 2;
  if ((c >> 2) == 60) r += 4;
  if ((c >> 2) == -4) r += 8;
  if (-c == 16) r += 16;
  if (~c == 15) r += 32;
  if (c / 2 == 120) r += 64;
  if (c % 7 == 2) r += 128;
  return r;
}
