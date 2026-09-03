/* Corner: calloc with nmemb*size overflowing size_t must return NULL
   (ISO C11 7.22.3.2p2 as clarified in C17). */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  void *p = calloc(SIZE_MAX / 2 + 2, 2);
  return p == 0 ? 1 : 2;
}
