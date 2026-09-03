/* Corner: _Alignof values and that object addresses satisfy their type's
   alignment (ISO C11 6.2.8, 6.5.3.4): only alignment RESIDUES are
   observed (0), never raw addresses. */
#include <stdio.h>
#include <stdint.h>
struct S { char c; long l; };
int main(void) {
  struct S s; double d; long long ll; char c; int a[3]; short sh;
  printf("%d %d %d %d %d ", (int)_Alignof(struct S), (int)_Alignof(double), (int)_Alignof(long long), (int)_Alignof(int[3]), (int)_Alignof(short));
  printf("%d %d %d %d %d\n", (int)((uintptr_t)&s % _Alignof(struct S)), (int)((uintptr_t)&d % 8), (int)((uintptr_t)&ll % 8), (int)((uintptr_t)&a % 4), (int)((uintptr_t)&sh % 2));
  return 0;
}
