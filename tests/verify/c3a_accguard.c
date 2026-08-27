/* R6 CENSUS c3a (arc-18 breadth campaign): the digit-accumulate
   OVERFLOW GUARDS of deps/libxml2/uri.c:350-355 (port > INT_MAX/10,
   port > INT_MAX - digit) — census row L5's arithmetic half, split
   from the scan loop (c3b). Two arguments (first two-arg corpus
   fixture; read2 atom).
   Theorem shape: forall seed, outcomes(acc10(21474836, 5)) =
   {Specified(214748365)}, no UB. */
int acc10(int p, int d)
{
  if (p > 214748364 || p < 0 || d < 0 || d > 9) {
    return -1;
  }
  if (p == 214748364 && d > 7) {
    return -1;
  }
  return p * 10 + d;
}

int main(void) { return acc10(21474836, 5); }
