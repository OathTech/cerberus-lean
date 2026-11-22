int main(void) {
  int r = 0;
  char c = '\377';
  unsigned int u = 1;
  long l = 1;
  if (c * u == 255u) r += 1;
  if (c * u == 4294967295u) r += 2;
  if (c * l == 255) r += 4;
  if (c * l == -1) r += 8;
  if ((c ? c : 0) > 0) r += 16;
  if (sizeof(c + c) == sizeof(int)) r += 32;
  return r;
}
