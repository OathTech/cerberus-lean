/* Corner: converting -1.5 to unsigned is UB (value not representable,
   ISO C11 6.3.1.4p1) -- unlike integer -1 -> unsigned which wraps. */
int main(void) {
  double m = -1.5;
  unsigned u = (unsigned)m;
  return u & 1;
}
