#include <stdatomic.h>
int main(void) {
  atomic_int x;
  int result = 0;
  {-{ { atomic_init(&x, 1); } ||| { result = atomic_load(&x); } }-};
  return result;
}
