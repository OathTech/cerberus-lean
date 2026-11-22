int main(void) {
  int r = 0;
  const char *s = "\377\200a";
  if (s[0] == 255) r += 1;
  if (s[0] == -1) r += 2;
  if (s[1] == 128) r += 4;
  if (s[0] + s[1] == 383) r += 8;
  if (s[0] + s[1] == -129) r += 16;
  char t[] = "\xfe";
  if (t[0] > 0) r += 32;
  if (sizeof t == 2) r += 64;
  return r;
}
