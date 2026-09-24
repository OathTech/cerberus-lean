unsigned long x = 0;
int main(void) {
  if (sizeof x < 2) return 0;
  unsigned char *p = (unsigned char *)&x;
  {-{ {p[0] = 1;} ||| {p[1] = 2;} }-};
  return 0;
}
