/* R6 EASY e1 (arc-18 breadth campaign): single compare + select —
   the branch-without-else floor. Census tie: E1 guard shape.
   Theorem shape: forall seed, outcomes(clamp0(-3)) = {Specified(0)},
   no UB. */
int clamp0(int x)
{
  if (x < 0) {
    return 0;
  }
  return x;
}

int main(void) { return clamp0(-3); }
