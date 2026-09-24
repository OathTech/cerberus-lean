unsigned long x = 0;
unsigned long result;
int main(void) {
  if (sizeof x < 2) return 0;
  unsigned char *p = (unsigned char *)&x;
  {-{ {result = x;} ||| {p[1] = 2;} }-};
  return 0;
}
