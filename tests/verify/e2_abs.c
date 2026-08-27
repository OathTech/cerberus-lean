/* R6 EASY e2 (arc-18 breadth campaign): if/else with arithmetic in
   one arm — the two-arm branch floor. Census tie: branch floor; the
   INT_MIN row documents the negation-overflow UB the spec excludes.
   Theorem shape: forall seed, outcomes(abs3(-5)) = {Specified(5)},
   no UB. */
int abs3(int x)
{
  if (x < 0) {
    return -x;
  } else {
    return x;
  }
}

int main(void) { return abs3(-5); }
