// datarace+Wna+Wna — two non-atomic stores race in every execution:
// outcome set {UB005_data_race} (upstream tests.ml row [] [Data_race]).
int main(void) {
  int x = 0;
  {-{ { x = 1; } ||| { x = 2; } }-};
  return x;
}
