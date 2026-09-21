// MP+na+na — the 2026-09-04 charter probe: a plain non-atomic race.
// Outcome set {UB005_data_race}. Measured "before" (both engines):
// Defined {value: "Specified(0)", ...} — the silent serialization finding.
int main(void) {
  int x = 0;
  int r = 7;
  {-{ { x = 1; } ||| { r = x; } }-};
  return r;
}
