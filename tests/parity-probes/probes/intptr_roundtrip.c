#include <stdint.h>
int main(void) {
  int x = 42;
  uintptr_t u = (uintptr_t)&x;
  int *p = (int *)u;
  return *p;  /* 42 */
}
