int main(void) {
  int a = 0, b = 0, c;
  c = (a = 3, b = a + 4, a * b);   /* 3*7 = 21 */
  int d = (c++, c--, c);           /* 21 */
  return c + d - 21;               /* 21 */
}
