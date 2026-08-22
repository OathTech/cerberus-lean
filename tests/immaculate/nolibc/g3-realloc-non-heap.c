// G3: realloc of a non-heap pointer is UB. Oracle -> UB179c
// (UB179c_non_matching_allocation_realloc); Lean currently -> UB179a
// (MerrUndefinedFree Free_non_matching) — WRONG UB FAMILY. S1 flips this.
#include <stdlib.h>
int main(void) {
  int x = 42;
  int *p = realloc(&x, sizeof(int) * 4);
  return p ? 0 : 1;
}
