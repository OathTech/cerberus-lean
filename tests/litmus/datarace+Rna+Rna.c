// datarace+Rna+Rna — two non-atomic loads do NOT race: outcome set {0}
// (upstream tests.ml row [0]).
int main(void) {
  int x = 0;
  int r1, r2;
  {-{ { r1 = x; } ||| { r2 = x; } }-};
  return 0;
}
