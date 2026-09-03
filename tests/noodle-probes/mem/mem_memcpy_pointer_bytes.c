/* Corner: copying a POINTER's object representation with memcpy preserves
   its value and (PVI) provenance; the copy is dereferenceable
   (ISO C11 6.2.6.1p4, 7.24.2.1). */
#include <string.h>
int main(void) {
  int x = 41;
  int *p = &x, *q = 0;
  memcpy(&q, &p, sizeof p);
  unsigned char buf[sizeof p];
  memcpy(buf, &p, sizeof p);
  int *r; memcpy(&r, buf, sizeof r);
  return (*q + *r) - x;   /* 41 */
}
