/* R6 EDGE x7 (arc-18 breadth campaign): EARLY RETURN INSIDE A LOOP —
   the multi-exit edge row (census E2/E4; corpus plan row x7). The
   instance is_pow2(6) EXITS THROUGH THE IN-LOOP RETURN (6 -> 3, then
   the odd check fires): the exit segment runs from a loop head
   through the return-0 path, not the guard-false path.
   Theorem shape: forall seed (guarded), outcomes(is_pow2(6)) =
   {Specified(0)}, no UB. */
int is_pow2(int n)
{
  while (n > 1) {
    if (n % 2 == 1) {
      return 0;
    }
    n = n / 2;
  }
  return 1;
}

int main(void) { return is_pow2(6); }
