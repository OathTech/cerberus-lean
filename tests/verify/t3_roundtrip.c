/* T3 (arc-7 verification slate): alloc, store, load points-to, frame.
   Theorem shape: forall v, outcomes = {Specified(v)}, no UB. */
int roundtrip(int v) { int x = v; return x; }

int main(void) { return roundtrip(42); }
