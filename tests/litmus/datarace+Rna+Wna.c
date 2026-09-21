// datarace+Rna+Wna — a non-atomic load races with a non-atomic store in
// every execution: outcome set {UB005_data_race} (upstream tests.ml row).
int main(void) {
  int x = 0;
  int r;
  {-{ { r = x; } ||| { x = 1; } }-};
  return r;
}
