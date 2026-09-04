// datarace+Wna_sc+sc_Rna — the store to x races with the load of x UNLESS
// the load of y reads 1 (then the seq_cst pair synchronizes and the load
// of x is hb-after the store, reading 1). Outcome set
// {Specified(1), UB005_data_race} (upstream tests.ml row [1] [Data_race]).
#include <stdatomic.h>
int main(void) {
  int x = 0;
  _Atomic(int) y = 0;
  int r1, r2;
  {-{ { x = 1;
        atomic_store_explicit(&y, 1, memory_order_seq_cst); }
  ||| { r1 = atomic_load_explicit(&y, memory_order_seq_cst);
        r2 = x; } }-};
  return r2;
}
