/* zero-discrepancy (2026-09-03, charter §4.2 R2 row): tests/noodle-probes/dynamic-addrs/da_malloc0_nonnull.c
   into the nolibc exec corpus; expected MATCH (Specified(1): malloc(0) is non-null in the model). */
#include <stdlib.h>
int main(void) {
  void *q = malloc(0);
  int r = (q != NULL);
  free(q);
  return r;
}
