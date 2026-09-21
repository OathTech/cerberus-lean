// globals+init+Wna_Wna — two FILE-SCOPE non-atomic objects, initialised at
// program startup, each written by ONE thread, both read after the join: race-
// free, outcome {3}. The pre-merge audit's probe p8a (F1): before S7 both
// engines reported UB005 because the initialisation stores were unordered
// against everything. sc_reference.py agrees.
int p = 0, q = 0;
int main(void) {
  {-{ { p = 1; } ||| { q = 2; } }-};
  return p + q;
}
