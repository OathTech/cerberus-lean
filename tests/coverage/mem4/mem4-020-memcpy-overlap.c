// mem4-020: memcpy with overlapping source and destination (UB in ISO C
// 7.24.2.1#2). The observable is what each engine reports.
#include <string.h>
int main(void) {
  char a[8] = {1, 2, 3, 4, 5, 6, 7, 8};
  memcpy(a + 1, a, 4);
  return a[0] * 10000 + a[1] * 1000 + a[2] * 100 + a[3] * 10 + a[4];
}
