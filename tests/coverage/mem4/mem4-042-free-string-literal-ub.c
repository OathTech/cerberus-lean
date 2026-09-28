// mem4-042: free of a string literal (not a heap allocation).
#include <stdlib.h>
int main(void) {
  char *s = "abc";
  free(s);
  return 0;
}
