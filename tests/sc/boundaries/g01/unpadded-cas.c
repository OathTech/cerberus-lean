#include <stdatomic.h>
struct P { int a; int b; };
int main(void) {
  struct P expected = {1, 2};
  _Atomic(struct P) object = expected;
  struct P desired = {3, 4};
  return atomic_compare_exchange_strong(&object, &expected, desired);
}
