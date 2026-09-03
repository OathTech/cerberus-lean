/* Corner: after realloc returns a DIFFERENT pointer the old one is dead;
   reading through it is UB (ISO C11 7.22.3.5p2, 6.2.4p2). If realloc
   returns the same pointer this program is defined and returns 1.
   Verdict-class agreement probe. */
#include <stdlib.h>
int main(void) {
  int *p = malloc(sizeof(int));
  *p = 1;
  int *q = realloc(p, 1000 * sizeof(int));
  int r = (q == p) ? *p : *q;
  free(q);
  return r;
}
