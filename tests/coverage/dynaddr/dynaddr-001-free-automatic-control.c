/* zero-discrepancy (2026-09-03, charter §4.2 R2 row): tests/noodle-probes/dynamic-addrs/da_control.c
   into the nolibc exec corpus; expected UB_MATCH (UB179a on fork oracle, upstream, Lean). */
#include <stdlib.h>
int main(void) {
  _Alignas(16) int x = 1;
  free(&x);
  return 0;
}
