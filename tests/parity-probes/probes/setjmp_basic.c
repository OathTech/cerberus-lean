#include <setjmp.h>
static jmp_buf env;
int main(void) {
  int v = setjmp(env);
  if (v == 7) return 42;
  longjmp(env, 7);
  return 1;
}
