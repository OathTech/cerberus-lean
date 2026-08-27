/* R6 EDGE x2 (arc-18 breadth campaign): BREAK out of a loop — the
   loop-exit edge row (census E3-lite; corpus plan row x2). cap10(273)
   runs 273 -> 27 (one full iteration), then the second head's body
   BREAKS at n = 27 < 100? no: breaks when n < 100 -- 27 < 100, so
   the break fires on iteration 2's guard path.
   Theorem shape: forall seed (guarded), outcomes(cap10(273)) =
   {Specified(27)}, no UB. */
int cap10(int n)
{
  while (n > 0) {
    if (n < 100) {
      break;
    }
    n = n / 10;
  }
  return n;
}

int main(void) { return cap10(273); }
