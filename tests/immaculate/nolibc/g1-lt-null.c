// G1: relational compare against a null pointer. Upstream lt_ptrval FAILs
// (MerrWIP "lt_ptrval ==> one null pointer") -> a kill path. Lean returns
// false silently -> a VALUE path (execution continues). S1 restores fail.
int main(void) {
  int x = 0;
  int *p = &x;
  int *q = (void*)0;
  if (p < q) return 1;   // reachable branch selection on a should-be-UB op
  return 0;
}
