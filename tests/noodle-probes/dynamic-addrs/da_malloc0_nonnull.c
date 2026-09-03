/* dynamic-addrs probe (d): does the model's malloc(0) return non-null?
   Returns 1 if non-null, 0 if NULL. (C11 7.22.3p1: implementation-defined.) */
#include <stdlib.h>
int main(void) {
  void *q = malloc(0);
  int r = (q != NULL);
  free(q);
  return r;
}
