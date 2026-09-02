/* T1 (arc-7 fixture): the smoke target.
   Theorem shape: forall x : int-range, outcomes of `id` under the
   symbolic-argument harness = {Specified(x)}, no UB. */
int id(int x) { return x; }

/* Concrete-instance differential anchor (sanity net under the theorem,
   never a substitute): main exercises the target at one point. */
int main(void) { return id(42); }
