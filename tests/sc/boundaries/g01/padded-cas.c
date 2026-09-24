#include <stdatomic.h>
struct P { unsigned char c; int i; };
int main(void) {
  struct P expected = {1, 2};
  _Atomic(struct P) object = expected;
  struct P desired = {3, 4};
  return atomic_compare_exchange_strong(&object, &expected, desired);
}
