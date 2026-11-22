int main(void) {
  char c = 0;
  int r = 0;
  r += _Generic(c, char: 1, signed char: 2, unsigned char: 3);
  r += 4 * _Generic(+c, int: 1, unsigned int: 2);
  r += 16 * _Generic('a', int: 1, char: 2);
  r += 64 * _Generic(&c, char *: 1, signed char *: 2, unsigned char *: 3);
  return r;
}
