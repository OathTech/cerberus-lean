/* Named-deviation register N1 (2026-09-28, served-surface audit P1-1): the
   bytes of a stored function pointer are the function symbol's fresh-supply
   number (impl_mem.ml:1203-1220, mirrored), which the engines do not share
   (oracle 502 today). Pinned DIFF with the Lean value: a Lean change, or the
   engines converging, flips the row. */
int f(void) { return 1; }
int main(void) {
  int (*fp)(void) = f;
  unsigned char *b = (unsigned char *)&fp;
  return b[0] + b[1] * 256;
}
