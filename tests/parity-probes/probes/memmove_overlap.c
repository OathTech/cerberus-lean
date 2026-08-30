#include <string.h>
int main(void) {
  char b[8] = {1,2,3,4,5,6,7,8};
  memmove(b+2, b, 4);      /* overlap forward */
  memmove(b, b+1, 4);      /* overlap backward */
  return b[0]+b[1]+b[2]+b[3]+b[4]+b[5];  /* derive by running */
}
