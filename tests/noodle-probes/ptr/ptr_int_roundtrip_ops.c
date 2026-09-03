/* Corner: pointer -> integer -> pointer round trips through arithmetic on
   the integer (PVI: provenance carried by the integer), intptr_t/uintptr_t/
   long (ISO C11 6.3.2.3p5-6, 7.20.1.4). */
#include <stdio.h>
#include <stdint.h>
int main(void) {
  int a[4] = {10, 20, 30, 40};
  uintptr_t u = (uintptr_t)&a[0];
  intptr_t s = (intptr_t)&a[0];
  long l = (long)&a[0];
  int *p1 = (int*)(u + sizeof(int));          /* &a[1] */
  int *p2 = (int*)(s + 2 * (intptr_t)sizeof(int)); /* &a[2] */
  int *p3 = (int*)(l + 12);                    /* &a[3] */
  int *p4 = (int*)((u ^ 0u) + 0);              /* &a[0] */
  printf("%d %d %d %d %d\n", *p1, *p2, *p3, *p4, (int)((uintptr_t)&a[3] - (uintptr_t)&a[1]));
  return 0;
}
