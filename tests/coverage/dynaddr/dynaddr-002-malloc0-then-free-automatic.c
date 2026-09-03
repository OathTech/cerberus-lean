/* zero-discrepancy (2026-09-03, charter §4.2 R2 row): tests/noodle-probes/dynamic-addrs/da_bug.c
   into the nolibc exec corpus; expected UB_MATCH (UB179a on all three engines — the C shape
   does NOT reproduce the tray-19 Core-level dynamic_addrs defect; argument temporaries). */
#include <stdlib.h>
int main(void) {
  void *q;
  _Alignas(16) int x = 1;
  q = malloc(0);
  free(&x);
  return 0;
}
