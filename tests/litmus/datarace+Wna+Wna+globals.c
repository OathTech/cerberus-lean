// datarace+Wna+Wna+globals — two non-atomic stores to one FILE-SCOPE object
// from two threads: a data race in every execution, {UB005_data_race} on both
// engines. Added by concurrency Phase 0 S7 (pre-merge audit F1): the verdict
// must come from the THREADS' racing stores, not from the initialisation store
// (which is sequenced before program startup). sc_reference.py agrees.
int x = 0;
int main(void) {
  {-{ { x = 1; } ||| { x = 2; } }-};
  return x;
}
