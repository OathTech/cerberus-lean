/* T5 (arc-7 fixture): bounded loop; loop-invariant rule + fuel
   erasure. Theorem shape: forall n in a stated range (0 <= n <= 100),
   outcomes = {Specified(n*(n-1)/2)}, no UB. */
int sum(int n) {
  int s = 0;
  for (int i = 0; i < n; i = i + 1) {
    s = s + i;
  }
  return s;
}

int main(void) { return sum(10); }
