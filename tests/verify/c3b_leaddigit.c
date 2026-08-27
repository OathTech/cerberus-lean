/* R6 CENSUS c3b (arc-18 breadth campaign): the scalar reduce loop —
   census row L5's loop half (split from the guards, c3a): a while
   loop rewriting the argument object per iteration (the T7 write1
   shape) with a data-dependent trip count. lead_digit(273): 273 ->
   27 -> 2, two iterations.
   Theorem shape: forall seed (guarded — digest pin + seed apartness),
   outcomes(lead_digit(273)) = {Specified(2)}, no UB. */
int lead_digit(int n)
{
  while (n > 9) {
    n = n / 10;
  }
  return n;
}

int main(void) { return lead_digit(273); }
