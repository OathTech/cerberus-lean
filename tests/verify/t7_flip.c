/* T7 (arc-18 R2 [F1]): BRANCH-IN-LOOP — the fixed-round breaker. The
   loop body BRANCHES and the arms have different statement counts, so
   per-iteration round counts are DATA-DEPENDENT: the uniform-k loop
   composition (iter_compose) cannot state this loop; the ∃-round
   segment judgment (Seg.iter) can. The arms ALTERNATE from 7
   (odd 7→4, even 4→3, odd 3→0), so the varying counts sit INSIDE
   the composed family. Theorem shape: ∀ seed (guarded — digest pin +
   seed apartness), outcomes(flip(7)) = {Specified(0)}, no UB. */
int flip(int n) {
  while (n > 0) {
    if (n % 2 == 0) {
      n = n - 1;
    } else {
      n = n - 1;
      n = n - 2;
    }
  }
  return n;
}

int main(void) { return flip(7); }
