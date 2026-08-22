// G3: realloc of a freed (dead) heap pointer. Oracle -> UB179d
// (dead_allocation_realloc); Lean currently -> UB179b. S1 flips this.
#include <stdlib.h>
int main(void) {
  int *p = malloc(sizeof(int) * 4);
  free(p);
  int *q = realloc(p, sizeof(int) * 8);
  return q ? 0 : 1;
}
