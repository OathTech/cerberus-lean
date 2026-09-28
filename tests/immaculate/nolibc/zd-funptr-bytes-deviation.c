/* Named-deviation register N1 (2026-09-28, served-surface audit P1-1): the
   bytes of a stored function pointer are the function symbol's fresh-supply
   number (impl_mem.ml:1168-1185, mirrored), which the engines do not share.
   Pinned DIFF with both values; a change on either side flips the row. */
int f(void) { return 1; }
int main(void) {
  int (*fp)(void) = f;
  unsigned char *b = (unsigned char *)&fp;
  return b[0] + b[1] * 256;
}
