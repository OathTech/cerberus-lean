/* Named-deviation register N2 (2026-09-29, pre-merge audit F2): Lean's
   Float.toBits canonicalizes every NaN, so the bytes of a stored NaN lose the
   sign and payload the oracle keeps (Int64.bits_of_float, impl_mem.ml:1190).
   inf - inf is a negative NaN on x86: the oracle's top byte is 255 (0xff),
   Lean's 127 (0x7f). Pinned DIFF with the Lean value. */
int main(void) {
  double inf = 1e309;
  double n = inf - inf;
  unsigned char *b = (unsigned char *)&n;
  return b[7];
}
