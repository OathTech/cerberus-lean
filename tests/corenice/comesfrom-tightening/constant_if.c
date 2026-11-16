/* Negative precision control: C integer truth is not a literal Core boolean. */
int main(void) {
  if (0) goto unused;
  return 0;
unused:
  return 47;
}
