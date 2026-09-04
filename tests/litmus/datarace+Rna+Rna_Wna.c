// datarace+Rna+Rna_Wna — the first thread's load races with the second
// thread's store in every execution (upstream note: this program caught a
// detector that only checked the hb-latest action): {UB005_data_race}.
int main(void) {
  int x = 0;
  int r1, r2;
  {-{ { r1 = x; } ||| { r2 = x; x = 1; } }-};
  return 0;
}
