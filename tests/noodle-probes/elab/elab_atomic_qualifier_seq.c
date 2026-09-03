/* Corner: _Atomic-qualified objects used in ordinary single-threaded code
   (ISO C11 6.7.3, 6.5.16.2): compound assignment and ++ are atomic RMWs.
   Concurrency is a declared stub boundary: verdict-class agreement probe. */
#include <stdio.h>
int main(void) {
  _Atomic int a = 5;
  a += 2; a++;
  int r = a;
  printf("%d\n", r);   /* 8 */
  return 0;
}
