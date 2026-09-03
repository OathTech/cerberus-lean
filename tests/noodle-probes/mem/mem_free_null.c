/* Corner: free(NULL) is a no-op (ISO C11 7.22.3.3p2). Cerberus's UB
   enumeration has a UB_CERB005_free_nullptr code: verdict probe. */
#include <stdlib.h>
int main(void) {
  free(0);
  int *p = 0;
  free(p);
  return 3;
}
