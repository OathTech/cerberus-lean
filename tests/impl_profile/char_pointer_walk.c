int main(void) {
  unsigned int w = 0x80ff7f01u;
  char *p = (char *)&w;
  int r = 0;
  for (int i = 0; i < 4; i++) if (p[i] < 0) r += 1 << i;
  if (p[1] + p[2] == 0x7f + 0xff) r += 16;
  return r;
}
