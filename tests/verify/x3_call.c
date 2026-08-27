/* R6 EDGE x3 (arc-18 breadth campaign): TWO-FUNCTION PROGRAM — the
   call-rule row (charter R6 explicit item: the first worked
   FnSpec/Summary instance; census §5 helper-call composition).
   Theorem shape: forall seed (guarded), outcomes(twice(5)) =
   {Specified(12)}, no UB. */
int inc3(int x)
{
  return x + 3;
}

int twice(int y)
{
  return inc3(y) + 4;
}

int main(void) { return twice(5); }
