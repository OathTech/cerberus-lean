/* Z2 probe (CerbFloat.lean:152-155 hex-float mantissa accumulated as a Nat
   then Float.ofNat + scaleB: >13 hex digits round before the exponent is
   applied; OCaml float_of_string rounds once, half-even). nolibc. */
int main(void) {
  double a = 0x1.00000000000008p0;   /* exactly halfway: ties-to-even -> 1.0 */
  double b = 0x1.00000000000018p0;   /* halfway: ties-to-even -> 0x1.0000000000002p0 */
  double c = 0x1.000000000000081p0;  /* just above halfway -> 0x1.0000000000001p0 */
  return (a == 0x1p0) * 100 + (b == 0x1.0000000000002p0) * 10 + (c == 0x1.0000000000001p0);
}
