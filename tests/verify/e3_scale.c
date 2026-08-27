/* R6 EASY e3 (arc-18 breadth campaign): straight-line arithmetic
   through a scalar local — the straight-line cost floor. Census tie:
   straight-line floor; the INT_MAX row documents the multiply
   overflow UB the spec excludes.
   Theorem shape: forall seed, outcomes(scale(7)) = {Specified(17)},
   no UB. */
int scale(int x)
{
  int y = x * 2 + 3;
  return y;
}

int main(void) { return scale(7); }
