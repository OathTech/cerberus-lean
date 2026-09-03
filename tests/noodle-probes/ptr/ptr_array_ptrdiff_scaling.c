/* Corner: subtraction of two pointers to ARRAY objects yields the number
   of array elements between them, i.e. the byte difference divided by
   sizeof(the pointed-to array type) (ISO C11 6.5.6p9). gcc: 2 1 2 2 1 8 */
#include <stdio.h>
struct S { int x, y, z; };
int main(void) {
  int a[3][4]; char c[2][3]; struct S s[3]; long long l[3];
  int (*p)[4] = a;
  int d1 = (int)(&a[2] - &a[0]);          /* 2 */
  int d2 = (int)(&c[1] - &c[0]);          /* 1 */
  int d3 = (int)(&s[2] - &s[0]);          /* 2 (struct control) */
  int d4 = (int)(&l[2] - &l[0]);          /* 2 (scalar control) */
  int d5 = (int)((p + 1) - p);            /* 1 */
  int d6 = (int)(&a[2][0] - &a[0][0]);    /* 8 (int-element control) */
  printf("%d %d %d %d %d %d\n", d1, d2, d3, d4, d5, d6);
  return 0;
}
