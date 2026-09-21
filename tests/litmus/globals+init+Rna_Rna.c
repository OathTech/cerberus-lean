// globals+init+Rna_Rna — one FILE-SCOPE non-atomic object, initialised at
// program startup and only READ by two threads: race-free, outcome {10}. The
// pre-merge audit's probe p8d (F1): before S7 both engines reported UB005 (the
// initialisation store vs. each read). sc_reference.py agrees.
int c = 5;
int main(void) {
  int r1, r2;
  {-{ { r1 = c; } ||| { r2 = c; } }-};
  return r1 + r2;
}
