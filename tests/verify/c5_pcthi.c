/* R6 CENSUS c5 (arc-18 breadth campaign): percent-encode high-nibble
   arithmetic — deps/libxml2/uri.c:1140-1142 (val / 0x10; hi + (hi >
   9 ? 'A'-10 : '0')), census row O2, ternary spelled as if/else.
   Theorem shape: forall seed, outcomes(pct_hi(65)) =
   {Specified(52)}, no UB. */
int pct_hi(int v)
{
  int hi = v / 16;
  if (hi > 9) {
    return hi + 55;
  }
  return hi + 48;
}

int main(void) { return pct_hi(65); }
