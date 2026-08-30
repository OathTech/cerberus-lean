#include <stdio.h>
int main(void) {
  char b[4];
  int n = snprintf(b, sizeof b, "%d", 123456);
  return n*2 + (b[3] == 0) + (b[0]=='1') + (b[2]=='3');  /* 12+1+1+1 = 15 */
}
