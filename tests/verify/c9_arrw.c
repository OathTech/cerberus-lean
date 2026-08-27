/* R6 CENSUS c9a (arc-18 breadth campaign): local array with
   constant-index stores/loads — the ARRAY-VOCABULARY isolation
   fixture (census §6/§3 substrate: array object create + indexed
   access, no loop, no variable index).
   Theorem shape: forall seed, outcomes(arr_rw(41)) =
   {Specified(42)}, no UB. */
int arr_rw(int x)
{
  int a[2];
  a[0] = x;
  a[1] = a[0] + 1;
  return a[1];
}

int main(void) { return arr_rw(41); }
