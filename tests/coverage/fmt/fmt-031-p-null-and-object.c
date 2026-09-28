// fmt-031: %p of a null pointer, of an object pointer and of a one-past-end
// pointer (object pointers only; function pointers are register N1).
#include <stdio.h>
int main(void) {
  int a[2];
  void *q = 0;
  return printf("[%p|%p|%p]\n", q, (void*)&a[0], (void*)(a + 2));
}
