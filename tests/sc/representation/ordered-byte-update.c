/* Legal ordered representation access. The final integer read combines the
   initialization with the byte write; no single executed whole-integer store
   supplied that final value. On the concrete target the result is 1. */
int main(void) {
  unsigned int x = 0;
  unsigned char *p = (unsigned char *)&x;
  p[0] = 1;
  return x != 0;
}
