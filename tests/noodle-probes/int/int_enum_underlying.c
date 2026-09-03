/* Corner: enumeration constants beyond int range and the enum's
   compatible integer type (ISO C11 6.7.2.2p4 impl-defined; 6.4.4.3). */
#include <stdio.h>
enum E1 { A = 0xFFFFFFFF };
enum E2 { B = -1, C = 2147483647 };
enum E3 { D = 0x100000000 };
int main(void) {
  enum E1 a = A; enum E2 b = B; enum E3 d = D;
  printf("%d ", (int)sizeof(a));      /* gcc: 4 */
  printf("%d ", (int)sizeof(b));      /* 4 */
  printf("%d ", (int)sizeof(d));      /* gcc: 8 */
  printf("%d ", a == -1);             /* gcc: 1 (unsigned int enum, -1 converts) */
  printf("%d ", A < 0);               /* 0: constant A has type int?? gcc: A is unsigned int */
  printf("%d ", b < 0);               /* 1 */
  printf("%d ", d > 0);               /* 1 */
  printf("%d\n", (int)sizeof(D));     /* gcc: 8 */
  return 0;
}
