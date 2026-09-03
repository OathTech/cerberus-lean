/* Corner: pointer-to-array arithmetic, decay, differences in elements and
   bytes (ISO C11 6.3.2.1p3, 6.5.6p9). */
#include <stdio.h>
int main(void) {
  int a[3][4];
  for (int i = 0; i < 3; i++) for (int j = 0; j < 4; j++) a[i][j] = i * 10 + j;
  int (*p)[4] = a;
  printf("%d %d %d %d ", (int)(sizeof a / sizeof a[0]), (int)sizeof(a + 0), (int)(&a[2] - &a[0]), (int)((char*)&a[1] - (char*)&a[0]));
  printf("%d %d %d %d\n", p[1][2], (*(p + 2))[3], (int)sizeof(*p), *(*(a + 2) + 1));
  return 0;
}
